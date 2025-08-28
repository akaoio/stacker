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
    
    # Parse arguments
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
            *)
                stacker_error "Unknown option: $1"
                return 1
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
        echo "  stacker: \"^2.0.0\""
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
            stacker_list_config
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

# Module initialization
cli_init() {
    stacker_debug "CLI module initialized"
    return 0
}