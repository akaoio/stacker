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
            stacker_set_config "$key" "$value"
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

# Install command - installs the application
stacker_cli_install() {
    stacker_require "install" || return 1
    
    local install_type=""
    local interval=""
    local auto_update=false
    local redundant=false
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --systemd)
                install_type="systemd"
                shift
                ;;
            --cron)
                install_type="cron"
                shift
                ;;
            --manual)
                install_type="manual"
                shift
                ;;
            --interval=*)
                interval="${1#--interval=}"
                shift
                ;;
            --auto-update|-a)
                auto_update=true
                shift
                ;;
            --redundant)
                redundant=true
                shift
                ;;
            *)
                stacker_error "Unknown install option: $1"
                return 1
                ;;
        esac
    done
    
    # Default to manual if not specified
    [ -z "$install_type" ] && install_type="manual"
    
    stacker_log "Installing with type: $install_type"
    [ -n "$interval" ] && stacker_log "Interval: $interval minutes"
    [ "$auto_update" = true ] && stacker_log "Auto-update enabled"
    [ "$redundant" = true ] && stacker_log "Redundant installation enabled"
    
    # Call appropriate install function
    case "$install_type" in
        systemd)
            stacker_install_systemd
            ;;
        cron)
            if [ -n "$interval" ]; then
                stacker_install_cron "$interval"
            else
                stacker_install_cron
            fi
            ;;
        manual)
            stacker_install_manual
            ;;
        *)
            stacker_error "Invalid install type: $install_type"
            return 1
            ;;
    esac
    
    # Enable auto-update if requested
    if [ "$auto_update" = true ]; then
        stacker_set_config "auto_update.enabled" "true"
    fi
    
    # Install redundant if requested
    if [ "$redundant" = true ]; then
        stacker_log "Installing redundant services..."
        stacker_install_systemd && stacker_install_cron
    fi
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
  add                   Add package from GitHub/GitLab/URL
  remove, rm            Remove package
  list, ls              List installed packages
  enable                Enable package in scope (local/user/system)
  disable               Disable package in scope
  search                Search for packages
  info                  Show package information
  
  # Framework Management
  init, -i              Initialize Stacker framework in current directory
  config, -c            Manage configuration settings
  install               Install Stacker-based application
  update, -u            Update Stacker-based application
  service, -s           Control Stacker service
  health                Check system health and diagnostics
  status                Show current status
  rollback, -r          Rollback to previous version
  version, -v           Show version information
  help, -h              Show help information

Options:
  --help, -h           Show this help
  --version, -v        Show version information
  --list-modules, -l   List all modules (loaded and available)
  --module-info, -m    Show module information

Command Examples:
  # Package Management - Like npm/yarn/bun but for POSIX systems
  stacker add gh:akaoio/air              # Add package from GitHub
  stacker add gh:akaoio/air --user       # Install for user only
  stacker add gh:akaoio/air --system     # Install system-wide
  stacker remove air                     # Remove package
  stacker list --user                    # List user packages
  stacker enable air --local             # Enable package locally
  
  # Framework Management
  stacker init --template=cli --name=mytool
  stacker config set update.interval 3600
  stacker install --systemd --auto-update
  stacker service status
  stacker health --verbose

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
    local action="$1"
    
    case "$action" in
        start|stop|restart|status|enable|disable)
            stacker_require "service" || return 1
            case "$action" in
                start) stacker_start_service ;;
                stop) stacker_stop_service ;;
                restart) stacker_restart_service ;;
                status) stacker_service_status ;;
                enable) stacker_enable_service ;;
                disable) stacker_disable_service ;;
            esac
            ;;
        --help|-h|"")
            cat << 'EOF'
Usage: stacker service COMMAND

Control Stacker service

Commands:
  start                 Start the service
  stop                  Stop the service
  restart               Restart the service
  status                Show service status
  enable                Enable service at boot
  disable               Disable service at boot

Examples:
  stacker service start
  stacker service status
  stacker service enable
EOF
            ;;
        *)
            stacker_error "Unknown service command: $action"
            stacker_error "Run 'stacker service --help' for usage information"
            return 1
            ;;
    esac
}

# Package management CLI functions
stacker_cli_add() {
    local url="$1"
    
    # Parse scope and remaining args  
    local parse_result=$(stacker_parse_scope_args "$@")
    local scope=$(echo "$parse_result" | cut -d' ' -f1)
    set -- $(echo "$parse_result" | cut -d' ' -f2-)
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                cat << 'EOF'
Usage: stacker add <package-url> [OPTIONS]

Add package from GitHub/GitLab/URL

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
  stacker add gh:akaoio/air              # Add from GitHub (user scope)
  stacker add gh:akaoio/air --system     # Add system-wide
  stacker add gl:myorg/tool --local      # Add locally to project
EOF
                return 0
                ;;
            -*)
                if [ -n "$url" ]; then
                    shift
                    continue
                fi
                url="$1"
                ;;
            *)
                if [ -z "$url" ]; then
                    url="$1"
                fi
                ;;
        esac
        shift
    done
    
    if [ -z "$url" ]; then
        stacker_error "Package URL required"
        stacker_error "Run 'stacker add --help' for usage information"
        return 1
    fi
    
    stacker_require "package" || return 1
    stacker_install_package "$url" "$scope"
}

stacker_cli_remove() {
    local name="$1"
    
    # Parse scope and remaining args
    local parse_result=$(stacker_parse_scope_args "$@")
    local scope=$(echo "$parse_result" | cut -d' ' -f1)
    set -- $(echo "$parse_result" | cut -d' ' -f2-)
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                cat << 'EOF'
Usage: stacker remove <package-name> [OPTIONS]

Remove installed package

Options:
  --local                   Remove from project (.stacker/)
  --user                    Remove from user (~/.local/share/stacker) [default]
  --system                  Remove from system (/usr/local/share/stacker)
  --help, -h                Show this help

Examples:
  stacker remove air                     # Remove from user scope
  stacker rm air --system                # Remove from system (rm alias)
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
        stacker_error "Run 'stacker remove --help' for usage information"
        return 1
    fi
    
    stacker_require "package" || return 1
    stacker_remove_package "$name" "$scope"
}

stacker_cli_list() {
    local all_scopes=false
    
    # Parse scope and remaining args
    local parse_result=$(stacker_parse_scope_args "$@")
    local scope=$(echo "$parse_result" | cut -d' ' -f1)
    set -- $(echo "$parse_result" | cut -d' ' -f2-)
    
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
        for s in local user system; do
            echo ""
            stacker_list_packages "$s"
        done
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

# Rollback CLI function
stacker_cli_rollback() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat << 'EOF'
Usage: stacker rollback [VERSION]

Rollback to previous version

Arguments:
  VERSION                   Specific version to rollback to (optional)

Examples:
  stacker rollback          # Rollback to previous version
  stacker rollback 1.2.3    # Rollback to specific version
EOF
        return 0
    fi
    
    stacker_require "update" || return 1
    stacker_rollback "$@"
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