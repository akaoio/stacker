#!/bin/sh
# Stacker CLI Module
# Command-line interface implementations

# Module metadata
STACKER_MODULE_NAME="cli"
STACKER_MODULE_VERSION="1.0.0"

# Initialize command - sets up Stacker in current directory
stacker_cli_init() {
    local template="service"
    local name=""
    local repo=""
    local script=""
    
    # Parse command-specific arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --template|-t)
                template="$2"
                shift 2
                ;;
            --name|-n)
                name="$2"
                shift 2
                ;;
            --repo)
                repo="$2"
                shift 2
                ;;
            --script)
                script="$2"
                shift 2
                ;;
            --help|-h)
                cat << 'EOF'
Usage: stacker init [OPTIONS]

Initialize Stacker framework in current directory

Options:
  --template, -t TYPE    Project template (service, cli, library) [default: service]
  --name, -n NAME        Project name
  --repo REPO            Repository URL
  --script SCRIPT        Main script name
  --help, -h             Show this help

Examples:
  stacker init                           # Initialize with interactive prompts
  stacker init --template=cli --name=mytool  # Initialize CLI application template
EOF
                return 0
                ;;
            --)
                shift
                break
                ;;
            --*|-*)
                stacker_unknown_option_error "init" "$1"
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Validate template
    case "$template" in
        service|cli|library)
            ;;
        *)
            stacker_error "Invalid template: $template (valid: service, cli, library)"
            return 1
            ;;
    esac
    
    stacker_log "Initializing Stacker project..."
    stacker_log "Template: $template"
    
    # Interactive prompts if values not provided
    if [ -z "$name" ]; then
        printf "Project name: "
        read name
        [ -z "$name" ] && name="$(basename "$(pwd)")"
    fi
    
    if [ -z "$repo" ]; then
        printf "Repository URL (optional): "
        read repo
    fi
    
    if [ -z "$script" ]; then
        printf "Main script name [$name.sh]: "
        read script
        [ -z "$script" ] && script="$name.sh"
    fi
    
    # Create project structure
    mkdir -p modules config
    
    # Create basic config
    {
        echo "name: \"$name\""
        echo "version: \"1.0.0\""
        echo "description: \"Stacker-based project\""
        echo "template: \"$template\""
        echo "repository: \"$repo\""
        echo "main_script: \"$script\""
        echo "dependencies:"
        echo "  stacker: \"^0.0.1\""
    } > stacker.yaml
    
    # Create main script if it doesn't exist
    if [ ! -f "$script" ]; then
        cat > "$script" << EOF
#!/bin/sh
# $name - Stacker-based application

# Load Stacker framework
STACKER_DIR="\${STACKER_DIR:-./stacker}"
. "\$STACKER_DIR/stacker.sh" || {
    echo "Error: Stacker framework not found" >&2
    exit 1
}

# Initialize Stacker
stacker_init || exit 1

# Your application code here
main() {
    stacker_log "Starting $name..."
    # Add your logic here
    stacker_log "$name completed successfully"
}

# Run main function
main "\$@"
EOF
        chmod +x "$script"
    fi
    
    stacker_log "✓ Project initialized successfully"
    stacker_log "  Name: $name"
    stacker_log "  Template: $template"
    stacker_log "  Script: $script"
    [ -n "$repo" ] && stacker_log "  Repository: $repo"
    
    return 0
}

# Configuration command - manages settings
stacker_cli_config() {
    stacker_require "config" || return 1
    
    local action="$1"
    local key="$2"
    local value="$3"
    
    case "$action" in
        --help|-h|"")
            cat << 'EOF'
Usage: stacker config <command> [OPTIONS]

Manage configuration settings

Commands:
  get KEY               Get configuration value
  set KEY VALUE         Set configuration value
  list                  List all configuration

Examples:
  stacker config get update.interval
  stacker config set update.interval 3600  
  stacker config list
EOF
            return 0
            ;;
        get)
            if [ -z "$key" ]; then
                stacker_error "Key required for get operation"
                return 1
            fi
            stacker_get_config "$key"
            ;;
        set)
            if [ -z "$key" ] || [ -z "$value" ]; then
                stacker_error "Key and value required for set operation"
                return 1
            fi
            stacker_save_config "$key" "$value"
            ;;
        list)
            stacker_show_config
            ;;
        *)
            stacker_error "Invalid config action: $action (use: get, set, list)"
            return 1
            ;;
    esac
}

# Install command - install packages or framework
stacker_cli_install() {
    local target="$1"
    
    # Handle help first
    if [ "$target" = "--help" ] || [ "$target" = "-h" ]; then
        cat << 'EOF'
Usage: stacker install <package-url> [OPTIONS]

Install packages from GitHub/GitLab/URL

Package URL formats:
  gh:user/repo[@ref]        GitHub repository
  gl:user/repo[@ref]        GitLab repository  
  https://example.git       Direct Git URL
  file:///local/path        Local directory

Options:
  --local                   Install in project (.stacker/)
  --user                    Install for user (~/.local/share/stacker) [default]
  --system                  Install system-wide (/usr/local/share/stacker)
  --help, -h                Show this help

Examples:
  stacker install gh:akaoio/air              # Install from GitHub (user scope)
  stacker install gh:akaoio/air --system     # Install system-wide
  stacker install gl:myorg/tool --local      # Install locally to project
EOF
        return 0
    fi
    
    if [ -z "$target" ]; then
        echo "Usage: stacker install <package-url> [OPTIONS]"
        echo "Run 'stacker install --help' for more information"
        return 1
    fi
    
    if [ "$target" = "stacker" ]; then
        echo "Framework already installed. Use: stacker update stacker"
        return 1
    fi
    
    # Install package using package management
    shift
    stacker_require "package" || return 1
    stacker_install_package "$target" "$@"
}

# Uninstall command - remove packages or framework
stacker_cli_uninstall() {
    local target="$1"
    
    # Handle help first
    if [ "$target" = "--help" ] || [ "$target" = "-h" ]; then
        cat << 'EOF'
Usage: stacker uninstall <package-name> [OPTIONS]

Remove installed packages

Options:
  --local                   Remove from project (.stacker/)
  --user                    Remove from user (~/.local/share/stacker) [default]
  --system                  Remove from system (/usr/local/share/stacker)
  --help, -h                Show this help

Examples:
  stacker uninstall air                     # Remove from user scope
  stacker uninstall air --system            # Remove from system
  stacker uninstall air --local             # Remove from project
EOF
        return 0
    fi
    
    if [ -z "$target" ]; then
        echo "Usage: stacker uninstall <package-name> [OPTIONS]"
        echo "Run 'stacker uninstall --help' for more information"
        return 1
    fi
    
    if [ "$target" = "stacker" ]; then
        echo "WARNING: This will remove Stacker framework completely!"
        printf "Are you sure? [y/N]: "
        read -r confirm
        case "$confirm" in
            [yY]|[yY][eE][sS])
                echo "Removing Stacker framework..."
                rm -rf ~/.local/share/stacker/
                rm -f ~/.local/bin/stacker
                rm -rf ~/.config/stacker/
                echo "✅ Stacker framework removed"
                ;;
            *)
                echo "Cancelled"
                ;;
        esac
        return 0
    fi
    
    # Remove package
    shift
    stacker_require "package" || return 1
    stacker_remove_package "$target" "$@"
}

# Health command - checks system health
stacker_cli_health() {
    local verbose=false
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose)
                verbose=true
                shift
                ;;
            *)
                stacker_error "Unknown health option: $1"
                return 1
                ;;
        esac
    done
    
    stacker_log "Checking system health..."
    
    # Basic health checks
    local issues=0
    
    # Check if initialized
    if [ ! -f "stacker.yaml" ]; then
        stacker_warn "Project not initialized (no stacker.yaml)"
        issues=$((issues + 1))
    else
        stacker_log "✓ Project configuration found"
    fi
    
    # Check main script
    if [ -n "$STACKER_MAIN_SCRIPT" ] && [ ! -f "$STACKER_MAIN_SCRIPT" ]; then
        stacker_warn "Main script not found: $STACKER_MAIN_SCRIPT"
        issues=$((issues + 1))
    else
        stacker_log "✓ Main script accessible"
    fi
    
    # Check dependencies
    if command -v git >/dev/null 2>&1; then
        stacker_log "✓ Git available"
    else
        stacker_warn "Git not available"
        issues=$((issues + 1))
    fi
    
    # Check permissions
    if [ -w "." ]; then
        stacker_log "✓ Write permissions OK"
    else
        stacker_warn "No write permissions in current directory"
        issues=$((issues + 1))
    fi
    
    # Verbose checks
    if [ "$verbose" = true ]; then
        stacker_log "\nDetailed diagnostics:"
        stacker_log "  Stacker version: $STACKER_VERSION"
        stacker_log "  Stacker directory: $STACKER_DIR"
        stacker_log "  Working directory: $(pwd)"
        stacker_log "  User: $(id -un)"
        stacker_log "  Shell: $0"
        stacker_log "  PATH: $PATH"
        
        # Module status
        stacker_log "\nLoaded modules: $STACKER_LOADED_MODULES"
        
        # System info
        if [ -f "/etc/os-release" ]; then
            . /etc/os-release
            stacker_log "  OS: ${PRETTY_NAME:-$NAME}"
        fi
        
        # Memory and disk
        if command -v free >/dev/null 2>&1; then
            stacker_log "  Memory: $(free -h | awk 'NR==2{print $3"/"$2}')"
        fi
        if command -v df >/dev/null 2>&1; then
            stacker_log "  Disk: $(df -h . | awk 'NR==2{print $3"/"$2" ("$5" used)"}')"
        fi
    fi
    
    # Summary
    if [ "$issues" -eq 0 ]; then
        stacker_log "\n✅ System health: GOOD (no issues found)"
        return 0
    else
        stacker_warn "\n⚠️ System health: WARNING ($issues issues found)"
        return 1
    fi
}

# Status command - shows current status
stacker_cli_status() {
    stacker_log "Stacker Status"
    stacker_log "=============="
    
    # Project info
    if [ -f "stacker.yaml" ]; then
        local name version
        name=$(grep '^name:' stacker.yaml 2>/dev/null | cut -d'"' -f2)
        version=$(grep '^version:' stacker.yaml 2>/dev/null | cut -d'"' -f2)
        
        stacker_log "Project: ${name:-unknown}"
        stacker_log "Version: ${version:-unknown}"
    else
        stacker_log "Project: Not initialized"
    fi
    
    # Framework info
    stacker_log "Framework: Stacker $STACKER_VERSION"
    stacker_log "Location: $STACKER_DIR"
    
    # Service status
    stacker_require "service" >/dev/null 2>&1 && {
        local service_status
        service_status=$(stacker_service_status 2>/dev/null)
        stacker_log "Service: ${service_status:-not installed}"
    }
    
    # Module status
    stacker_log "Modules loaded: ${STACKER_LOADED_MODULES:-none}"
    
    return 0
}

# Main help function
stacker_help() {
    cat << EOF
Stacker Framework v${STACKER_VERSION:-0.0.1} - Universal Shell Framework (Modular)

Usage:
  stacker [COMMAND] [OPTIONS]

Commands:
  # Package Management (Universal POSIX Package Manager)
  install               Install packages or framework
  uninstall             Remove packages or framework
  update                Update packages, framework, or everything
  list, ls              List installed packages
  search                Search for packages
  info                  Show package information
  
  # Service Management
  service               Manage package services (install/start/stop)
  daemon                Manage package daemons (background processes)
  watchdog              Manage package monitoring (health checks)
  
  # Framework Management
  config, -c            Manage configuration settings
  rollback, -r          Rollback to previous version
  version, -v           Show version information
  help, -h              Show help information

Options:
  --help, -h           Show this help
  --version, -v        Show version information
  --list-modules, -l   List all modules (loaded and available)
  --module-info, -m    Show module information

Command Examples:
  # Package Management - Clean system tool pattern
  stacker install gh:nginx/nginx        # Install nginx package
  stacker uninstall gh:nginx/nginx      # Remove nginx package
  stacker update gh:nginx/nginx         # Update nginx package
  stacker update stacker                # Update framework
  stacker update                        # Update everything
  
  # Service Management
  stacker service gh:nginx/nginx install # Install nginx as systemd service
  stacker daemon gh:redis/redis install  # Install redis as background daemon
  stacker watchdog gh:postgresql/postgresql install # Install postgres with monitoring

For detailed help on any command:
  stacker [COMMAND] --help

Module Management (when sourced):
  stacker_require "module1 module2"  # Load specific modules
  stacker_list_loaded_modules        # Show loaded modules
  stacker_list_available_modules     # Show available modules
  stacker_module_info "module_name"  # Show module information
EOF
}

# Version information
stacker_version() {
    echo "Stacker Framework v${STACKER_VERSION:-0.0.1}"
    echo "Universal Shell Framework - Modular Architecture"
    echo ""
    echo "Components:"
    echo "  Core Module:      src/sh/module/core.sh"
    echo "  CLI Module:       src/sh/module/cli.sh"
    echo "  Config Module:    src/sh/module/config.sh"
    echo "  Install Module:   src/sh/module/install.sh"
    echo "  Service Module:   src/sh/module/service.sh"
    echo "  Update Module:    src/sh/module/update.sh"
    echo "  Package Module:   src/sh/module/package.sh"
    echo "  Watchdog Module:  src/sh/module/watchdog.sh"
    echo ""
    echo "Loaded Modules:   ${STACKER_LOADED_MODULES:-none}"
}

# Service CLI functions
stacker_cli_service() {
    local target="$1"
    local action="$2"
    
    if [ -z "$target" ] || [ -z "$action" ]; then
        cat << 'EOF'
Usage: stacker service <package> <command>

Manage package services

Commands:
  install               Install package as systemd service
  start                 Start the service
  stop                  Stop the service
  restart               Restart the service
  status                Show service status
  enable                Enable service at boot
  disable               Disable service at boot

Examples:
  stacker service gh:nginx/nginx install
  stacker service gh:nginx/nginx start
  stacker service gh:redis/redis status
EOF
        return 1
    fi
    
    case "$action" in
        install)
            echo "Installing $target as service..."
            stacker_require "package" || return 1
            stacker_cli_install "$target" --service
            ;;
        start|stop|restart|status|enable|disable)
            stacker_require "service" || return 1
            echo "Managing $target service: $action"
            echo "Service management not yet available - install package first"
            return 1
            ;;
        *)
            echo "Unknown service command: $action"
            echo "Run 'stacker service <package> --help' for usage information"
            return 1
            ;;
    esac
}

# Daemon management CLI functions
stacker_cli_daemon() {
    local target="$1"
    local action="$2"
    
    if [ -z "$target" ] || [ -z "$action" ]; then
        cat << 'EOF'
Usage: stacker daemon <package> <command>

Manage package daemons

Commands:
  install               Install package as background daemon
  uninstall             Remove daemon setup
  start                 Start the daemon
  stop                  Stop the daemon
  restart               Restart the daemon
  status                Show daemon status

Examples:
  stacker daemon gh:redis/redis install
  stacker daemon gh:postgresql/postgresql start
  stacker daemon gh:mongodb/mongo status
EOF
        return 1
    fi
    
    case "$action" in
        install)
            echo "Installing $target as daemon..."
            stacker_require "package" || return 1
            stacker_cli_install "$target" --daemon
            ;;
        uninstall)
            echo "Removing $target daemon setup..."
            echo "Daemon removal not yet available"
            return 1
            ;;
        start|stop|restart|status)
            echo "Managing $target daemon: $action"
            echo "Daemon control not yet available"
            return 1
            ;;
        *)
            echo "Unknown daemon command: $action"
            return 1
            ;;
    esac
}

# Watchdog management CLI functions  
stacker_cli_watchdog() {
    local target="$1"
    local action="$2"
    
    if [ -z "$target" ] || [ -z "$action" ]; then
        cat << 'EOF'
Usage: stacker watchdog <package> <command>

Manage package watchdogs

Commands:
  install               Install package with health monitoring
  uninstall             Remove watchdog setup
  start                 Start the watchdog
  stop                  Stop the watchdog
  status                Show watchdog status

Examples:
  stacker watchdog gh:nginx/nginx install
  stacker watchdog gh:apache/httpd start
  stacker watchdog gh:traefik/traefik status
EOF
        return 1
    fi
    
    case "$action" in
        install)
            echo "Installing $target with watchdog..."
            stacker_require "package" || return 1
            stacker_cli_install "$target" --watchdog
            ;;
        uninstall)
            echo "Removing $target watchdog setup..."
            echo "Watchdog removal not yet available"
            return 1
            ;;
        start|stop|restart|status)
            echo "Managing $target watchdog: $action"
            echo "Watchdog control not yet available"
            return 1
            ;;
        *)
            echo "Unknown watchdog command: $action"
            return 1
            ;;
    esac
}

# Package management CLI functions

stacker_cli_list() {
    local all_scopes=false
    local scope="user"  # Default scope
    
    # Parse arguments directly (don't use broken scope parser for no-arg case)
    while [ $# -gt 0 ]; do
        case "$1" in
            --local)
                scope="local"
                shift
                ;;
            --user)  
                scope="user"
                shift
                ;;
            --system)
                scope="system" 
                shift
                ;;
            --all|-a)
                all_scopes=true
                shift
                ;;
            --help|-h)
                cat << 'EOF'
Usage: stacker list [OPTIONS]

List installed packages

Options:
  --local                   List project packages (.stacker/)
  --user                    List user packages (~/.local/share/stacker) [default]
  --system                  List system packages (/usr/local/share/stacker)
  --all, -a                 List packages from all scopes
  --help, -h                Show this help

Examples:
  stacker list                           # List user packages
  stacker list --system                  # List system packages
  stacker ls --all                       # List all packages (ls alias)
EOF
                return 0
                ;;
            *)
                echo "Unknown list option: $1"
                return 1
                ;;
        esac
    done
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --all|-a)
                all_scopes=true
                ;;
            --help|-h)
                cat << 'EOF'
Usage: stacker list [OPTIONS]

List installed packages

Options:
  --local                   List project packages (.stacker/)
  --user                    List user packages (~/.local/share/stacker) [default]
  --system                  List system packages (/usr/local/share/stacker)
  --all, -a                 List packages from all scopes
  --help, -h                Show this help

Examples:
  stacker list                           # List user packages
  stacker list --system                  # List system packages
  stacker ls --all                       # List all packages (ls alias)
EOF
                return 0
                ;;
            *)
                stacker_error "Unknown list option: $1"
                return 1
                ;;
        esac
        shift
    done
    
    stacker_require "package" || return 1
    if [ "$all_scopes" = true ]; then
        stacker_list_packages "all"
    else
        stacker_list_packages "$scope"
    fi
}

stacker_cli_enable() {
    local name="$1"
    
    # Parse scope and remaining args
    local parse_result=$(stacker_parse_scope_args "$@")
    local scope=$(echo "$parse_result" | cut -d' ' -f1)
    set -- $(echo "$parse_result" | cut -d' ' -f2-)
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                cat << 'EOF'
Usage: stacker enable <package-name> [OPTIONS]

Enable installed package

Options:
  --local                   Enable in project (.stacker/enabled)
  --user                    Enable for user (~/.config/stacker/enabled) [default]
  --system                  Enable system-wide (/etc/stacker/enabled)
  --help, -h                Show this help

Examples:
  stacker enable air                     # Enable for user
  stacker enable air --system            # Enable system-wide
EOF
                return 0
                ;;
            -*)
                if [ -n "$name" ]; then
                    shift
                    continue
                fi
                name="$1"
                ;;
            *)
                if [ -z "$name" ]; then
                    name="$1"
                fi
                ;;
        esac
        shift
    done
    
    if [ -z "$name" ]; then
        stacker_error "Package name required"
        stacker_error "Run 'stacker enable --help' for usage information"
        return 1
    fi
    
    stacker_require "package" || return 1
    stacker_enable_package "$name" "$scope"
}

stacker_cli_disable() {
    local name="$1"
    
    # Parse scope and remaining args
    local parse_result=$(stacker_parse_scope_args "$@")
    local scope=$(echo "$parse_result" | cut -d' ' -f1)
    set -- $(echo "$parse_result" | cut -d' ' -f2-)
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                cat << 'EOF'
Usage: stacker disable <package-name> [OPTIONS]

Disable installed package (keeps package, removes from enabled)

Options:
  --local                   Disable in project (.stacker/enabled)
  --user                    Disable for user (~/.config/stacker/enabled) [default]
  --system                  Disable system-wide (/etc/stacker/enabled)
  --help, -h                Show this help

Examples:
  stacker disable air                    # Disable for user
  stacker disable air --local            # Disable locally
EOF
                return 0
                ;;
            -*)
                if [ -n "$name" ]; then
                    shift
                    continue
                fi
                name="$1"
                ;;
            *)
                if [ -z "$name" ]; then
                    name="$1"
                fi
                ;;
        esac
        shift
    done
    
    if [ -z "$name" ]; then
        stacker_error "Package name required"
        stacker_error "Run 'stacker disable --help' for usage information"
        return 1
    fi
    
    stacker_require "package" || return 1
    stacker_disable_package "$name" "$scope"
}

stacker_cli_search() {
    local query="$1"
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$query" ]; then
        cat << 'EOF'
Usage: stacker search <query>

Search for packages (coming soon)

Arguments:
  query                     Search query

Examples:
  stacker search web        # Search for web-related packages
  stacker search cli        # Search for CLI tools
EOF
        return 0
    fi
    
    stacker_require "package" || return 1
    stacker_search_packages "$query"
}

stacker_cli_info() {
    local name="$1"
    
    # Parse scope and remaining args
    local parse_result=$(stacker_parse_scope_args "$@")
    local scope=$(echo "$parse_result" | cut -d' ' -f1)
    set -- $(echo "$parse_result" | cut -d' ' -f2-)
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                cat << 'EOF'
Usage: stacker info <package-name> [OPTIONS]

Show package information

Options:
  --local                   Show info for project package (.stacker/)
  --user                    Show info for user package (~/.local/share/stacker) [default]
  --system                  Show info for system package (/usr/local/share/stacker)
  --help, -h                Show this help

Examples:
  stacker info air                       # Show info for user package
  stacker info air --system              # Show info for system package
EOF
                return 0
                ;;
            -*)
                if [ -n "$name" ]; then
                    shift
                    continue
                fi
                name="$1"
                ;;
            *)
                if [ -z "$name" ]; then
                    name="$1"
                fi
                ;;
        esac
        shift
    done
    
    if [ -z "$name" ]; then
        stacker_error "Package name required"
        stacker_error "Run 'stacker info --help' for usage information"
        return 1
    fi
    
    stacker_require "package" || return 1
    stacker_package_info "$name" "$scope"
}


# Shared scope argument parsing function  
stacker_parse_scope_args() {
    local scope="user"  # default scope
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --local)
                scope="local"
                ;;
            --user)
                scope="user"
                ;;
            --system)
                scope="system"
                ;;
            *)
                # Return remaining args and scope
                echo "$scope $*"
                return 0
                ;;
        esac
        shift
    done
    
    echo "$scope"
}

# Module initialization
cli_init() {
    stacker_debug "CLI module initialized"
    return 0
}