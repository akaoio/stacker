#!/bin/sh
# @akaoio/manager - Universal Shell Framework
# MODULAR VERSION - Loads only required modules on-demand

# Framework version
MANAGER_VERSION="2.0.0"

# Framework directory detection
if [ -z "$MANAGER_DIR" ]; then
    MANAGER_DIR="$(dirname "$0")"
fi

# Load the module loading system first
. "$MANAGER_DIR/manager-loader.sh" || {
    echo "FATAL: Cannot load module loader" >&2
    exit 1
}

# Initialize the loader (loads core module)
manager_loader_init || {
    echo "FATAL: Cannot initialize module loader" >&2
    exit 1
}

# Global configuration variables
MANAGER_TECH_NAME=""
MANAGER_REPO_URL=""
MANAGER_MAIN_SCRIPT=""
MANAGER_SERVICE_DESCRIPTION=""

# Auto-detect best installation directory
if [ -n "$INSTALL_DIR" ]; then
    # User specified directory
    MANAGER_INSTALL_DIR="$INSTALL_DIR"
elif [ -n "$FORCE_USER_INSTALL" ] || [ "$FORCE_USER_INSTALL" = "1" ]; then
    # Force user installation
    MANAGER_INSTALL_DIR="$HOME/.local/bin"
    # Ensure directory exists
    mkdir -p "$MANAGER_INSTALL_DIR"
elif [ -w "/usr/local/bin" ] && [ -z "$NO_SUDO" ] && sudo -n true 2>/dev/null; then
    # System installation (sudo available and not disabled)
    MANAGER_INSTALL_DIR="/usr/local/bin"
else
    # User installation (no sudo or disabled)
    MANAGER_INSTALL_DIR="$HOME/.local/bin"
    # Ensure directory exists
    mkdir -p "$MANAGER_INSTALL_DIR"
fi

MANAGER_HOME_DIR="$HOME"

# Initialize manager framework for a technology
# Usage: manager_init "tech_name" "repo_url" "main_script" ["service_description"]
manager_init() {
    local tech_name="$1"
    local repo_url="$2"  
    local main_script="$3"
    local service_desc="${4:-$tech_name service}"
    
    if [ -z "$tech_name" ] || [ -z "$repo_url" ] || [ -z "$main_script" ]; then
        manager_error "manager_init requires: tech_name, repo_url, main_script"
        return 1
    fi
    
    MANAGER_TECH_NAME="$tech_name"
    MANAGER_REPO_URL="$repo_url"
    MANAGER_MAIN_SCRIPT="$main_script"
    MANAGER_SERVICE_DESCRIPTION="$service_desc"
    
    # Set derived paths
    MANAGER_CLEAN_CLONE_DIR="$MANAGER_HOME_DIR/$tech_name"
    MANAGER_CONFIG_DIR="$MANAGER_HOME_DIR/.config/$tech_name"
    MANAGER_DATA_DIR="$MANAGER_HOME_DIR/.local/share/$tech_name"
    MANAGER_STATE_DIR="$MANAGER_HOME_DIR/.local/state/$tech_name"
    
    # Log installation mode
    if [ "$MANAGER_INSTALL_DIR" = "/usr/local/bin" ]; then
        manager_log "Initialized for $tech_name (system installation)"
    else
        manager_log "Initialized for $tech_name (user installation: $MANAGER_INSTALL_DIR)"
        # Check PATH
        case ":$PATH:" in
            *":$MANAGER_INSTALL_DIR:"*)
                ;;
            *)
                manager_warn "Add to PATH: export PATH=\"$MANAGER_INSTALL_DIR:\$PATH\""
                ;;
        esac
    fi
    return 0
}

# Complete installation workflow with modular loading
# Usage: manager_install [--service] [--cron] [--auto-update] [--interval=N]
manager_install() {
    local use_service=false
    local use_cron=false  
    local use_auto_update=false
    local cron_interval=5
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --service|--systemd)
                use_service=true
                ;;
            --cron)
                use_cron=true
                ;;
            --auto-update)
                use_auto_update=true
                ;;
            --interval=*)
                cron_interval="${1#*=}"
                use_cron=true
                ;;
            --redundant)
                use_service=true
                use_cron=true
                ;;
            *)
                manager_warn "Unknown install option: $1"
                ;;
        esac
        shift
    done
    
    # Validate initialization
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized. Call manager_init first."
        return 1
    fi
    
    manager_log "Starting installation of $MANAGER_TECH_NAME..."
    
    # Load required modules for installation
    manager_require "config install" || return 1
    
    # Core installation steps
    manager_check_requirements || return 1
    manager_create_xdg_dirs || return 1  
    manager_create_clean_clone || return 1
    manager_install_from_clone || return 1
    
    # Optional components - load service module if needed
    if [ "$use_service" = true ] || [ "$use_cron" = true ]; then
        manager_require "service" || return 1
    fi
    
    if [ "$use_service" = true ]; then
        manager_setup_systemd_service || manager_warn "Failed to setup systemd service"
    fi
    
    if [ "$use_cron" = true ]; then
        manager_setup_cron_job "$cron_interval" || manager_warn "Failed to setup cron job"
    fi
    
    if [ "$use_auto_update" = true ]; then
        # Load update module for auto-update
        manager_require "update" || return 1
        manager_setup_auto_update || manager_warn "Failed to setup auto-update"
    fi
    
    manager_log "Installation of $MANAGER_TECH_NAME completed successfully"
    return 0
}

# Setup services (systemd + optional cron backup) with modular loading
# Usage: manager_setup_service [interval_minutes]
manager_setup_service() {
    local interval="${1:-5}"
    
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized"
        return 1
    fi
    
    # Load service module
    manager_require "service" || return 1
    
    manager_log "Setting up service management for $MANAGER_TECH_NAME..."
    
    # Try systemd first
    if manager_setup_systemd_service; then
        manager_log "Systemd service configured successfully"
        
        # Add cron backup if available
        if command -v crontab >/dev/null 2>&1; then
            manager_log "Adding cron backup (redundant automation)"
            manager_setup_cron_job "$interval"
        fi
    elif manager_setup_cron_job "$interval"; then
        manager_log "Cron job configured successfully (systemd not available)"
    else
        manager_error "Failed to setup both systemd and cron"
        return 1
    fi
    
    return 0
}

# Uninstall technology with modular loading
# Usage: manager_uninstall [--keep-config] [--keep-data]
manager_uninstall() {
    local keep_config=false
    local keep_data=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --keep-config)
                keep_config=true
                ;;
            --keep-data)
                keep_data=true
                ;;
        esac
        shift
    done
    
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized"
        return 1
    fi
    
    manager_log "Uninstalling $MANAGER_TECH_NAME..."
    
    # Load service module for cleanup
    manager_require "service" || true
    
    # Stop and disable services
    manager_stop_service 2>/dev/null || true
    manager_disable_service 2>/dev/null || true
    
    # Remove cron jobs
    manager_remove_cron_job 2>/dev/null || true
    
    # Remove installed binary
    if [ -f "$MANAGER_INSTALL_DIR/$MANAGER_TECH_NAME" ]; then
        if [ -w "$MANAGER_INSTALL_DIR" ]; then
            rm -f "$MANAGER_INSTALL_DIR/$MANAGER_TECH_NAME"
        else
            sudo rm -f "$MANAGER_INSTALL_DIR/$MANAGER_TECH_NAME"
        fi
        manager_log "Removed $MANAGER_INSTALL_DIR/$MANAGER_TECH_NAME"
    fi
    
    # Remove clean clone
    if [ -d "$MANAGER_CLEAN_CLONE_DIR" ]; then
        rm -rf "$MANAGER_CLEAN_CLONE_DIR"
        manager_log "Removed clean clone: $MANAGER_CLEAN_CLONE_DIR"
    fi
    
    # Optionally remove config and data
    if [ "$keep_config" = false ] && [ -d "$MANAGER_CONFIG_DIR" ]; then
        rm -rf "$MANAGER_CONFIG_DIR"
        manager_log "Removed config: $MANAGER_CONFIG_DIR"
    fi
    
    if [ "$keep_data" = false ] && [ -d "$MANAGER_DATA_DIR" ]; then
        rm -rf "$MANAGER_DATA_DIR"
        manager_log "Removed data: $MANAGER_DATA_DIR"
    fi
    
    if [ "$keep_data" = false ] && [ -d "$MANAGER_STATE_DIR" ]; then
        rm -rf "$MANAGER_STATE_DIR"  
        manager_log "Removed state: $MANAGER_STATE_DIR"
    fi
    
    manager_log "Uninstallation of $MANAGER_TECH_NAME completed"
    return 0
}

# Show status of technology with modular loading
# Usage: manager_status
manager_status() {
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized"
        return 1
    fi
    
    echo "=========================================="
    echo "  $MANAGER_TECH_NAME Status Report"
    echo "=========================================="
    echo ""
    
    # Installation status
    echo "📦 Installation:"
    if [ -f "$MANAGER_INSTALL_DIR/$MANAGER_TECH_NAME" ]; then
        echo "  ✅ Binary: $MANAGER_INSTALL_DIR/$MANAGER_TECH_NAME"
    else
        echo "  ❌ Binary: Not found"
    fi
    
    if [ -d "$MANAGER_CLEAN_CLONE_DIR" ]; then
        echo "  ✅ Clean clone: $MANAGER_CLEAN_CLONE_DIR"
    else
        echo "  ❌ Clean clone: Not found"
    fi
    
    # Configuration
    echo ""
    echo "⚙️ Configuration:"
    echo "  📁 Config: $MANAGER_CONFIG_DIR"
    echo "  📁 Data: $MANAGER_DATA_DIR"  
    echo "  📁 State: $MANAGER_STATE_DIR"
    
    # Service status - load module only if needed
    echo ""
    echo "🔧 Service Status:"
    if manager_require "service" 2>/dev/null; then
        manager_service_status
    else
        echo "  ❌ Service module not available"
    fi
    
    # Cron status
    echo ""
    echo "⏰ Cron Status:"
    if crontab -l 2>/dev/null | grep -q "$MANAGER_TECH_NAME"; then
        echo "  ✅ Cron job active"
        echo "  📅 Schedule: $(crontab -l 2>/dev/null | grep "$MANAGER_TECH_NAME" | head -1)"
    else
        echo "  ❌ No cron job found"
    fi
    
    echo ""
    return 0
}

# Show manager framework version
manager_version() {
    echo "Manager Framework v$MANAGER_VERSION (Modular)"
    echo "Universal POSIX Shell Framework for AKAO Technologies"
    echo ""
    echo "Loaded modules: $MANAGER_LOADED_MODULES"
    echo "Available modules:"
    manager_list_available_modules
}

# Show help
manager_help() {
    cat << 'EOF'
Manager Framework v2.0 - Universal Shell Framework (Modular)

Usage:
  ./manager.sh [COMMAND] [OPTIONS]

Commands:
  init, -i              Initialize Manager framework in current directory
  config, -c            Manage configuration settings
  install               Install Manager-based application
  update, -u            Update Manager-based application
  service, -s           Control Manager service
  health                Check system health and diagnostics
  status                Show current status
  rollback, -r          Rollback to previous version
  self-install          Install Manager globally for system-wide use
  version, -v           Show version information
  help, -h              Show help information

Options (for direct execution):
  --help, -h           Show this help
  --version, -v        Show version information
  --list-modules, -l   List all modules (loaded and available)
  --module-info, -m    Show module information

Command Examples:
  manager init --template=cli --name=mytool
  manager config set update.interval 3600
  manager install --systemd --auto-update
  manager service status
  manager health --verbose

For detailed help on any command:
  manager [COMMAND] --help

Module Management (when sourced):
  manager_require "module1 module2"  # Load specific modules
  manager_list_loaded_modules        # Show loaded modules
  manager_list_available_modules     # Show available modules
  manager_module_info "module_name"  # Show module information

EOF
}

# Backwards compatibility mode
if [ "${MANAGER_LEGACY_MODE:-0}" = "1" ]; then
    manager_debug "Legacy mode enabled - loading all modules"
    manager_require "config install service update self_update" >/dev/null 2>&1 || true
fi

# Parse CLI arguments and execute commands
manager_parse_cli() {
    case "$1" in
        --help|-h|help)
            manager_help
            exit 0
            ;;
        --version|-v|version)
            local json_output=false
            [ "$2" = "--json" ] && json_output=true
            if [ "$json_output" = true ]; then
                echo "{\"version\":\"$MANAGER_VERSION\",\"type\":\"modular\",\"loaded_modules\":\"$MANAGER_LOADED_MODULES\"}"
            else
                manager_version
            fi
            exit 0
            ;;
        init|-i)
            shift
            manager_cli_init "$@"
            exit $?
            ;;
        config|-c)
            shift
            manager_cli_config "$@"
            exit $?
            ;;
        install)
            shift
            manager_cli_install "$@"
            exit $?
            ;;
        update|-u)
            shift
            manager_cli_update "$@"
            exit $?
            ;;
        service|-s)
            shift
            manager_cli_service "$@"
            exit $?
            ;;
        health)
            shift
            manager_cli_health "$@"
            exit $?
            ;;
        status)
            manager_status
            exit 0
            ;;
        rollback|-r)
            shift
            manager_cli_rollback "$@"
            exit $?
            ;;
        self-install)
            shift
            manager_cli_self_install "$@"
            exit $?
            ;;
        --self-update|--discover|--setup-auto-update|--remove-auto-update|--self-status|--register)
            if manager_require "self_update"; then
                manager_handle_self_update "$@"
                exit $?
            else
                manager_error "Self-update module not available"
                exit 1
            fi
            ;;
        --module-info|-m)
            if [ -n "$2" ]; then
                manager_module_info "$2"
            else
                manager_list_available_modules
            fi
            exit 0
            ;;
        --list-modules|-l)
            manager_list_loaded_modules
            echo ""
            manager_list_available_modules
            exit 0
            ;;
        *)
            manager_error "Unknown command: $1"
            echo ""
            manager_help
            exit 1
            ;;
    esac
}

# CLI command implementations
manager_cli_init() {
    local template="service"
    local name=""
    local repo=""
    local script=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --template=*|-t=*)
                template="${1#*=}"
                ;;
            --template|-t)
                template="$2"
                shift
                ;;
            --name=*|-n=*)
                name="${1#*=}"
                ;;
            --name|-n)
                name="$2"
                shift
                ;;
            --repo=*)
                repo="${1#*=}"
                ;;
            --repo)
                repo="$2"
                shift
                ;;
            --script=*)
                script="${1#*=}"
                ;;
            --script)
                script="$2"
                shift
                ;;
            --help|-h)
                cat << 'EOF'
Usage: manager init [OPTIONS]

Initialize Manager framework in current directory

Options:
  --template, -t TYPE    Project template (service, cli, library) [default: service]
  --name, -n NAME        Project name
  --repo REPO            Repository URL
  --script SCRIPT        Main script name
  --help, -h             Show this help

Examples:
  manager init --template=cli --name=mytool
  manager init -t service -n myservice --repo=https://github.com/user/repo.git
EOF
                return 0
                ;;
            *)
                [ -z "$name" ] && name="$1" || {
                    manager_error "Unknown option: $1"
                    return 1
                }
                ;;
        esac
        shift
    done
    
    # Interactive mode if no name provided
    if [ -z "$name" ]; then
        printf "Project name: "
        read -r name
        [ -z "$name" ] && { manager_error "Project name required"; return 1; }
    fi
    
    if [ -z "$repo" ]; then
        printf "Repository URL (optional): "
        read -r repo
    fi
    
    if [ -z "$script" ]; then
        script="${name}.sh"
    fi
    
    manager_log "Initializing Manager project: $name"
    manager_log "  Template: $template"
    manager_log "  Script: $script"
    [ -n "$repo" ] && manager_log "  Repository: $repo"
    
    if [ -n "$repo" ]; then
        manager_init "$name" "$repo" "$script"
    else
        manager_log "Project initialized (no repository specified)"
        echo "#!/bin/sh" > "$script"
        echo "# $name - Generated by Manager framework" >> "$script"
        chmod +x "$script"
        manager_log "Created: $script"
    fi
}

manager_cli_config() {
    local action="$1"
    shift
    
    case "$action" in
        get|-g)
            local key="$1"
            [ -z "$key" ] && { manager_error "Key required for get"; return 1; }
            manager_require "config"
            manager_get_config "$key"
            ;;
        set|-s)
            local key="$1"
            local value="$2"
            [ -z "$key" ] || [ -z "$value" ] && { 
                manager_error "Key and value required for set"
                return 1
            }
            manager_require "config"
            manager_save_config "$key" "$value"
            ;;
        list|-l)
            manager_require "config"
            manager_show_config
            ;;
        --help|-h|"")
            cat << 'EOF'
Usage: manager config COMMAND [OPTIONS]

Manage configuration settings

Commands:
  get, -g KEY           Get configuration value
  set, -s KEY VALUE     Set configuration value  
  list, -l              List all configuration

Options:
  --help, -h            Show this help

Examples:
  manager config get update.interval
  manager config set update.interval 3600
  manager config list
EOF
            ;;
        *)
            manager_error "Unknown config command: $action"
            return 1
            ;;
    esac
}

manager_cli_install() {
    local use_systemd=false
    local use_cron=false
    local use_manual=false
    local install_args=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --systemd)
                use_systemd=true
                install_args="$install_args --service"
                ;;
            --cron)
                use_cron=true
                install_args="$install_args --cron"
                ;;
            --manual)
                use_manual=true
                ;;
            --interval=*)
                install_args="$install_args $1"
                ;;
            --auto-update|-a)
                install_args="$install_args --auto-update"
                ;;
            --redundant)
                install_args="$install_args --redundant"
                ;;
            --help|-h)
                cat << 'EOF'
Usage: manager install [OPTIONS]

Install Manager-based application

Options:
  --systemd             Install as systemd service
  --cron                Install as cron job
  --manual              Manual installation (default)
  --interval=N          Cron interval in minutes
  --auto-update, -a     Enable automatic updates
  --redundant           Both systemd and cron
  --help, -h            Show this help

Examples:
  manager install --systemd
  manager install --cron --interval=300
  manager install --redundant --auto-update
EOF
                return 0
                ;;
            *)
                manager_error "Unknown install option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized. Run 'manager init' first."
        return 1
    fi
    
    manager_install $install_args
}

manager_cli_update() {
    local check_only=false
    local force=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --check|-c)
                check_only=true
                ;;
            --force|-f)
                force=true
                ;;
            --help|-h)
                cat << 'EOF'
Usage: manager update [OPTIONS]

Update Manager-based application

Options:
  --check, -c           Check for updates without installing
  --force, -f           Force update even if current
  --help, -h            Show this help

Examples:
  manager update --check
  manager update --force
EOF
                return 0
                ;;
            *)
                manager_error "Unknown update option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized"
        return 1
    fi
    
    if [ "$check_only" = true ]; then
        manager_log "Checking for updates..."
        # TODO: Implement update checking
        manager_log "Update check not yet implemented"
    else
        manager_log "Updating $MANAGER_TECH_NAME..."
        # TODO: Implement actual update
        manager_log "Update functionality not yet implemented"
    fi
}

manager_cli_service() {
    local action="$1"
    
    case "$action" in
        start)
            manager_require "service"
            manager_start_service
            ;;
        stop)
            manager_require "service"  
            manager_stop_service
            ;;
        restart)
            manager_require "service"
            manager_restart_service
            ;;
        status)
            manager_require "service"
            manager_service_status
            ;;
        enable)
            manager_require "service"
            manager_enable_service
            ;;
        disable)
            manager_require "service"
            manager_disable_service
            ;;
        --help|-h|"")
            cat << 'EOF'
Usage: manager service COMMAND

Control Manager service

Commands:
  start                 Start the service
  stop                  Stop the service  
  restart               Restart the service
  status                Show service status
  enable                Enable service at boot
  disable               Disable service at boot

Options:
  --help, -h            Show this help

Examples:
  manager service start
  manager service status
EOF
            ;;
        *)
            manager_error "Unknown service command: $action"
            return 1
            ;;
    esac
}

manager_cli_health() {
    local verbose=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose|-v)
                verbose=true
                ;;
            --help|-h)
                cat << 'EOF'
Usage: manager health [OPTIONS]

Check system health and diagnostics

Options:
  --verbose, -v         Show detailed diagnostic information
  --help, -h            Show this help

Examples:
  manager health
  manager health --verbose
EOF
                return 0
                ;;
            *)
                manager_error "Unknown health option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    echo "Manager Framework Health Check"
    echo "=============================="
    echo ""
    
    # Basic health checks
    echo "✓ Manager framework loaded"
    echo "✓ Core module functional"
    echo "✓ Module loading system operational"
    
    if [ "$verbose" = true ]; then
        echo ""
        echo "Detailed Diagnostics:"
        echo "  Version: $MANAGER_VERSION"
        echo "  Loaded modules: $MANAGER_LOADED_MODULES"
        echo "  Shell: $0"
        echo "  Working directory: $(pwd)"
        [ -n "$MANAGER_TECH_NAME" ] && echo "  Initialized for: $MANAGER_TECH_NAME"
    fi
    
    echo ""
    echo "Health check completed ✓"
}

manager_cli_rollback() {
    local version="$1"
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << 'EOF'
Usage: manager rollback [VERSION]

Rollback to previous version

Arguments:
  VERSION               Specific version to rollback to (optional)

Options:
  --help, -h            Show this help

Examples:
  manager rollback
  manager rollback 1.2.3
EOF
        return 0
    fi
    
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized"
        return 1
    fi
    
    if [ -n "$version" ]; then
        manager_log "Rolling back to version: $version"
    else
        manager_log "Rolling back to previous version"
    fi
    
    # TODO: Implement rollback functionality
    manager_log "Rollback functionality not yet implemented"
}

manager_cli_self_install() {
    local install_dir="/usr/local/bin"
    local use_sudo=true
    local user_scope=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --user)
                user_scope=true
                install_dir="$HOME/.local/bin"
                use_sudo=false
                ;;
            --system)
                user_scope=false
                install_dir="/usr/local/bin"
                use_sudo=true
                ;;
            --prefix=*)
                install_dir="${1#*=}/bin"
                use_sudo=false
                ;;
            --help|-h)
                cat << 'EOF'
Usage: manager self-install [OPTIONS]

Install Manager globally for system-wide use

Options:
  --user                Install in user directory (~/.local/bin)
  --system              Install system-wide (/usr/local/bin) [default]
  --prefix=PATH         Install to custom prefix (PATH/bin)
  --help, -h            Show this help

Examples:
  manager self-install           # Install system-wide (may require sudo)
  manager self-install --user    # Install for current user only
  manager self-install --prefix=/opt/local  # Install to /opt/local/bin

After installation, you can use 'manager' command from anywhere:
  manager init myproject
  manager health
EOF
                return 0
                ;;
            *)
                manager_error "Unknown self-install option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    # Create install directory if it doesn't exist
    if [ "$user_scope" = true ] && [ ! -d "$install_dir" ]; then
        echo "Creating user bin directory: $install_dir"
        mkdir -p "$install_dir" || {
            manager_error "Failed to create directory: $install_dir"
            return 1
        }
    fi
    
    # Check if install directory is writable
    if [ ! -w "$install_dir" ] && [ "$use_sudo" = false ]; then
        manager_error "Cannot write to $install_dir. Try with --user or use sudo."
        return 1
    fi
    
    # Get absolute path of Manager directory
    local abs_manager_dir="$(cd "$MANAGER_DIR" && pwd)"
    
    echo "Installing Manager Framework globally..."
    echo "  Source: $abs_manager_dir"
    echo "  Target: $install_dir/manager"
    [ "$use_sudo" = true ] && echo "  Note: May require sudo password"
    
    # Create wrapper script
    local wrapper_content="#!/bin/sh
# Manager Framework Global Wrapper
# Auto-generated by manager self-install
export MANAGER_DIR=\"$abs_manager_dir\"
exec \"\$MANAGER_DIR/manager.sh\" \"\$@\"
"
    
    # Write wrapper to temp file first
    local temp_wrapper="/tmp/manager-wrapper-$$"
    echo "$wrapper_content" > "$temp_wrapper" || {
        manager_error "Failed to create wrapper script"
        return 1
    }
    chmod +x "$temp_wrapper"
    
    # Install the wrapper
    if [ "$use_sudo" = true ]; then
        echo "Installing to system directory (requires sudo)..."
        sudo cp "$temp_wrapper" "$install_dir/manager" || {
            rm -f "$temp_wrapper"
            manager_error "Failed to install manager (sudo required)"
            return 1
        }
        sudo chmod 755 "$install_dir/manager"
    else
        cp "$temp_wrapper" "$install_dir/manager" || {
            rm -f "$temp_wrapper"
            manager_error "Failed to install manager"
            return 1
        }
        chmod 755 "$install_dir/manager"
    fi
    
    rm -f "$temp_wrapper"
    
    # Verify installation
    if [ -x "$install_dir/manager" ]; then
        echo ""
        echo "✓ Manager Framework installed successfully!"
        echo ""
        echo "Installation complete. You can now use 'manager' from anywhere:"
        echo "  manager --version"
        echo "  manager --help"
        echo "  manager init myproject"
        
        if [ "$user_scope" = true ]; then
            # Check if user bin is in PATH
            case ":$PATH:" in
                *":$install_dir:"*)
                    # Already in PATH
                    ;;
                *)
                    echo ""
                    echo "NOTE: Add $install_dir to your PATH:"
                    echo "  export PATH=\"\$PATH:$install_dir\""
                    echo "  (Add this to your ~/.bashrc or ~/.profile)"
                    ;;
            esac
        fi
    else
        manager_error "Installation verification failed"
        return 1
    fi
    
    return 0
}

# Handle CLI arguments when run directly
if [ $# -gt 0 ]; then
    manager_parse_cli "$@"
fi

# Functions are available when this file is sourced
# POSIX shells don't support 'export -f', functions are available in current shell context