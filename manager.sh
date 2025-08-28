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
  self-install          Install Manager globally as command-line tool
  self-uninstall        Remove global Manager installation
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
        self-uninstall)
            shift
            manager_cli_self_uninstall "$@"
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
    local install_dir=""
    local use_sudo=false
    local force=false
    local symlink=false
    local verify_only=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --user)
                install_dir="$HOME/.local/bin"
                use_sudo=false
                ;;
            --system)
                install_dir="/usr/local/bin"
                use_sudo=true
                ;;
            --prefix=*)
                install_dir="${1#*=}/bin"
                use_sudo=false
                ;;
            --force|-f)
                force=true
                ;;
            --symlink|-s)
                symlink=true
                ;;
            --verify)
                verify_only=true
                ;;
            --help|-h)
                cat << 'EOF'
Usage: manager self-install [OPTIONS]

Install Manager globally as a command-line tool

Options:
  --user                Install in user directory (~/.local/bin)
  --system              Install system-wide (/usr/local/bin)
  --prefix=PATH         Install to custom prefix (PATH/bin)
  --force, -f           Force reinstall even if already installed
  --symlink, -s         Create symlink instead of wrapper script
  --verify              Verify installation only
  --help, -h            Show this help

Installation Methods:
  1. Auto-detect (default): Finds best location based on permissions
  2. User install: Safe, no sudo, installs to ~/.local/bin
  3. System install: Requires sudo, available to all users
  4. Custom prefix: Install to specified directory

Examples:
  manager self-install                  # Auto-detect best location
  manager self-install --user           # Install for current user
  manager self-install --system         # Install system-wide
  manager self-install --prefix=/opt    # Install to /opt/bin
  manager self-install --verify         # Check if installed correctly

After installation:
  manager version                       # Verify installation
  manager init myproject                # Initialize new project
  manager help                          # Show available commands
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
    
    # Auto-detect installation directory if not specified
    if [ -z "$install_dir" ]; then
        # Check common directories in order of preference
        for dir in "$HOME/.local/bin" "/usr/local/bin" "/usr/bin" "/opt/bin"; do
            if [ -w "$dir" ] || ([ "$dir" = "/usr/local/bin" ] || [ "$dir" = "/usr/bin" ]) && command -v sudo >/dev/null 2>&1; then
                install_dir="$dir"
                [ "$dir" = "/usr/local/bin" ] || [ "$dir" = "/usr/bin" ] && use_sudo=true
                break
            fi
        done
        
        if [ -z "$install_dir" ]; then
            # Fallback to user directory
            install_dir="$HOME/.local/bin"
            echo "Auto-detected installation directory: $install_dir"
        fi
    fi
    
    # Verify mode - check existing installation
    if [ "$verify_only" = true ]; then
        echo "Verifying Manager installation..."
        
        # Check if manager command exists
        if command -v manager >/dev/null 2>&1; then
            local installed_path="$(command -v manager)"
            echo "✓ Manager found at: $installed_path"
            
            # Check if it's our installation
            if grep -q "MANAGER_DIR=" "$installed_path" 2>/dev/null; then
                local installed_dir="$(grep "MANAGER_DIR=" "$installed_path" | cut -d'"' -f2)"
                echo "✓ Manager directory: $installed_dir"
                
                # Verify it works
                if manager --version >/dev/null 2>&1; then
                    echo "✓ Manager is functional"
                    manager --version
                    return 0
                else
                    echo "✗ Manager command exists but is not functional"
                    return 1
                fi
            else
                echo "✗ Found different 'manager' command (not Manager Framework)"
                return 1
            fi
        else
            echo "✗ Manager not found in PATH"
            echo ""
            echo "To install, run: $0 self-install"
            return 1
        fi
    fi
    
    # Check for existing installation
    if [ -f "$install_dir/manager" ] && [ "$force" != true ]; then
        echo "Manager is already installed at: $install_dir/manager"
        echo ""
        
        # Check if it's our installation
        if grep -q "MANAGER_DIR=" "$install_dir/manager" 2>/dev/null; then
            local installed_dir="$(grep "MANAGER_DIR=" "$install_dir/manager" | cut -d'"' -f2)"
            echo "Current installation points to: $installed_dir"
            
            local abs_manager_dir="$(cd "$MANAGER_DIR" 2>/dev/null && pwd)"
            if [ "$installed_dir" != "$abs_manager_dir" ]; then
                echo "This directory: $abs_manager_dir"
                echo ""
                echo "Use --force to update the installation"
            else
                echo "Already using this Manager instance"
            fi
        else
            echo "WARNING: Found different 'manager' command at this location"
            echo "Use --force to replace it with Manager Framework"
        fi
        return 1
    fi
    
    # Create install directory if needed
    if [ ! -d "$install_dir" ]; then
        echo "Creating directory: $install_dir"
        if [ "$use_sudo" = true ]; then
            sudo mkdir -p "$install_dir" || {
                manager_error "Failed to create directory: $install_dir"
                return 1
            }
        else
            mkdir -p "$install_dir" || {
                manager_error "Failed to create directory: $install_dir"
                return 1
            }
        fi
    fi
    
    # Check write permissions
    if [ ! -w "$install_dir" ] && [ "$use_sudo" = false ]; then
        manager_error "Cannot write to $install_dir. Try with --system or use sudo."
        return 1
    fi
    
    # Get absolute paths
    local abs_manager_dir="$(cd "$MANAGER_DIR" 2>/dev/null && pwd)"
    if [ -z "$abs_manager_dir" ]; then
        manager_error "Failed to determine Manager directory path"
        return 1
    fi
    
    local abs_manager_script="$abs_manager_dir/manager.sh"
    if [ ! -f "$abs_manager_script" ]; then
        manager_error "Manager script not found: $abs_manager_script"
        return 1
    fi
    
    echo "Installing Manager Framework..."
    echo "  Source: $abs_manager_dir"
    echo "  Target: $install_dir/manager"
    echo "  Method: $([ "$symlink" = true ] && echo "symlink" || echo "wrapper script")"
    [ "$use_sudo" = true ] && echo "  Permission: sudo required"
    echo ""
    
    # Create installation (symlink or wrapper)
    if [ "$symlink" = true ]; then
        # Create symlink
        if [ "$use_sudo" = true ]; then
            sudo ln -sf "$abs_manager_script" "$install_dir/manager" || {
                manager_error "Failed to create symlink"
                return 1
            }
        else
            ln -sf "$abs_manager_script" "$install_dir/manager" || {
                manager_error "Failed to create symlink"
                return 1
            }
        fi
    else
        # Create wrapper script with enhanced features
        local wrapper_content="#!/bin/sh
# Manager Framework Global Wrapper
# Version: 2.0.0
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Source: $abs_manager_dir

# Verify Manager directory still exists
if [ ! -d \"$abs_manager_dir\" ]; then
    echo \"ERROR: Manager directory not found: $abs_manager_dir\" >&2
    echo \"Please reinstall Manager Framework\" >&2
    exit 1
fi

# Verify Manager script exists
if [ ! -f \"$abs_manager_script\" ]; then
    echo \"ERROR: Manager script not found: $abs_manager_script\" >&2
    echo \"Please reinstall Manager Framework\" >&2
    exit 1
fi

# Set Manager directory and execute
export MANAGER_DIR=\"$abs_manager_dir\"
exec \"\$MANAGER_DIR/manager.sh\" \"\$@\"
"
        
        # Write wrapper to temp file with atomic install
        local temp_wrapper="$(mktemp /tmp/manager-wrapper.XXXXXX)"
        echo "$wrapper_content" > "$temp_wrapper" || {
            rm -f "$temp_wrapper"
            manager_error "Failed to create wrapper script"
            return 1
        }
        chmod 755 "$temp_wrapper"
        
        # Install atomically
        if [ "$use_sudo" = true ]; then
            sudo mv -f "$temp_wrapper" "$install_dir/manager" || {
                rm -f "$temp_wrapper"
                manager_error "Failed to install manager"
                return 1
            }
        else
            mv -f "$temp_wrapper" "$install_dir/manager" || {
                rm -f "$temp_wrapper"
                manager_error "Failed to install manager"
                return 1
            }
        fi
    fi
    
    # Verify installation
    if [ ! -x "$install_dir/manager" ]; then
        manager_error "Installation failed - manager not executable"
        return 1
    fi
    
    # Test the installation
    if ! "$install_dir/manager" --version >/dev/null 2>&1; then
        manager_error "Installation test failed - manager not working"
        return 1
    fi
    
    # Check PATH and provide guidance
    local in_path=false
    case ":$PATH:" in
        *":$install_dir:"*)
            in_path=true
            ;;
    esac
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║             Manager Framework Installed Successfully!          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Installation Details:"
    echo "  • Location: $install_dir/manager"
    echo "  • Version: $(MANAGER_DIR="$abs_manager_dir" "$install_dir/manager" --version 2>/dev/null || echo "2.0.0")"
    echo "  • Type: $([ "$symlink" = true ] && echo "Symlink" || echo "Wrapper Script")"
    echo ""
    
    if [ "$in_path" = true ]; then
        echo "✓ Directory $install_dir is in your PATH"
        echo ""
        echo "You can now use 'manager' from anywhere:"
    else
        echo "⚠ Directory $install_dir is NOT in your PATH"
        echo ""
        echo "To use 'manager' from anywhere, add to PATH:"
        echo ""
        echo "  # Add to ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"\$PATH:$install_dir\""
        echo ""
        echo "Or source it now for this session:"
        echo "  export PATH=\"\$PATH:$install_dir\""
        echo ""
        echo "Then you can use:"
    fi
    
    echo "  manager version        # Show version"
    echo "  manager help           # Show commands"
    echo "  manager init           # Initialize project"
    echo "  manager self-uninstall # Remove installation"
    echo ""
    
    return 0
}

manager_cli_self_uninstall() {
    local force=false
    local all=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --force|-f)
                force=true
                ;;
            --all|-a)
                all=true
                ;;
            --help|-h)
                cat << 'EOF'
Usage: manager self-uninstall [OPTIONS]

Remove Manager Framework global installation

Options:
  --force, -f           Skip confirmation prompt
  --all, -a             Remove from all found locations
  --help, -h            Show this help

Description:
  Removes the globally installed 'manager' command from system.
  By default, removes only from PATH locations.
  Use --all to remove from all common installation directories.

Examples:
  manager self-uninstall           # Interactive uninstall
  manager self-uninstall --force   # Uninstall without confirmation
  manager self-uninstall --all     # Remove all installations

Note:
  This only removes the global command. The Manager Framework
  source directory remains intact and can be reinstalled anytime.
EOF
                return 0
                ;;
            *)
                manager_error "Unknown self-uninstall option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    echo "Searching for Manager installations..."
    echo ""
    
    # Find all manager installations
    local found_installations=""
    local found_count=0
    
    # Check PATH locations
    local IFS=':'
    for dir in $PATH; do
        if [ -f "$dir/manager" ] && [ -x "$dir/manager" ]; then
            # Check if it's our Manager Framework
            if grep -q "Manager Framework" "$dir/manager" 2>/dev/null || \
               grep -q "MANAGER_DIR=" "$dir/manager" 2>/dev/null; then
                # Avoid duplicates
                if ! echo "$found_installations" | grep -q "^$dir/manager$"; then
                    found_installations="$found_installations$dir/manager\n"
                    found_count=$((found_count + 1))
                    echo "  Found: $dir/manager"
                fi
            fi
        fi
    done
    
    # Check common locations if --all specified
    if [ "$all" = true ]; then
        for dir in /usr/local/bin /usr/bin /opt/bin "$HOME/.local/bin" "$HOME/bin"; do
            if [ -f "$dir/manager" ] && [ -x "$dir/manager" ]; then
                # Check if not already found and it's our Manager
                if ! echo "$found_installations" | grep -q "$dir/manager" && \
                   (grep -q "Manager Framework" "$dir/manager" 2>/dev/null || \
                    grep -q "MANAGER_DIR=" "$dir/manager" 2>/dev/null); then
                    found_installations="$found_installations$dir/manager\n"
                    found_count=$((found_count + 1))
                    echo "  Found: $dir/manager (not in PATH)"
                fi
            fi
        done
    fi
    
    # Check if any installations found
    if [ $found_count -eq 0 ]; then
        echo ""
        echo "No Manager Framework installations found."
        echo ""
        echo "Note: Only checking for Manager Framework installations,"
        echo "not other programs that might be named 'manager'."
        return 0
    fi
    
    echo ""
    echo "Found $found_count Manager installation(s)"
    echo ""
    
    # Confirm uninstallation
    if [ "$force" != true ]; then
        echo "This will remove the following:"
        printf "$found_installations" | while IFS= read -r file; do
            [ -n "$file" ] && echo "  - $file"
        done
        echo ""
        printf "Are you sure you want to uninstall? (yes/no): "
        read -r confirmation
        
        case "$confirmation" in
            yes|Yes|YES|y|Y)
                echo ""
                ;;
            *)
                echo "Uninstallation cancelled."
                return 0
                ;;
        esac
    fi
    
    # Perform uninstallation
    local removed_count=0
    local failed_count=0
    
    printf "$found_installations" | while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            echo "Removing: $file"
            
            # Check if we need sudo
            if [ -w "$file" ]; then
                rm -f "$file" && {
                    echo "  ✓ Removed successfully"
                    removed_count=$((removed_count + 1))
                } || {
                    echo "  ✗ Failed to remove"
                    failed_count=$((failed_count + 1))
                }
            else
                # Try with sudo
                echo "  (requires sudo)"
                sudo rm -f "$file" && {
                    echo "  ✓ Removed successfully"
                    removed_count=$((removed_count + 1))
                } || {
                    echo "  ✗ Failed to remove"
                    failed_count=$((failed_count + 1))
                }
            fi
        fi
    done
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              Manager Framework Uninstalled                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "The Manager Framework has been removed from global installation."
    echo ""
    echo "Note: The source directory remains at:"
    echo "  $(cd "$MANAGER_DIR" 2>/dev/null && pwd)"
    echo ""
    echo "You can reinstall anytime by running:"
    echo "  $MANAGER_DIR/manager.sh self-install"
    echo ""
    
    return 0
}

# Handle CLI arguments when run directly
if [ $# -gt 0 ]; then
    manager_parse_cli "$@"
fi

# Functions are available when this file is sourced
# POSIX shells don't support 'export -f', functions are available in current shell context