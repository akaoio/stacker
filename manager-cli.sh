#!/bin/sh
# Manager CLI - Standalone command for manager framework management
# Can be installed system-wide for managing all manager installations

set -e

# Detect manager framework location
MANAGER_DIR=""
if [ -f "$(dirname "$0")/manager.sh" ]; then
    MANAGER_DIR="$(dirname "$0")"
elif [ -f "$HOME/.local/share/manager/manager.sh" ]; then
    MANAGER_DIR="$HOME/.local/share/manager"
elif [ -f "/usr/local/share/manager/manager.sh" ]; then
    MANAGER_DIR="/usr/local/share/manager"
else
    echo "Error: Manager framework not found" >&2
    echo "Please install manager framework first" >&2
    exit 1
fi

# Load manager framework
. "$MANAGER_DIR/manager.sh"

# Show usage
show_usage() {
    cat << 'EOF'
Manager Framework CLI - Universal system management

Usage: manager <command> [options]

Self-Update Commands:
  discover              Discover all manager installations
  update               Update all manager frameworks  
  setup-auto-update    Enable weekly auto-updates
  remove-auto-update   Remove auto-update system
  status               Show manager framework status

Project Management:
  init <name> <repo> <script> [desc]    Initialize project
  install [options]                     Install current project
  uninstall [options]                   Uninstall current project
  service [start|stop|status]           Manage project service

Examples:
  manager discover                      # Find all installations
  manager update                       # Update all managers
  manager setup-auto-update           # Enable weekly updates
  manager status                      # Show overall status
  
  manager init myapp https://github.com/user/myapp.git main.py
  manager install --redundant --auto-update
  manager service status

EOF
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        # Self-update commands
        discover)
            manager_handle_self_update --discover
            ;;
        update)
            manager_handle_self_update --self-update
            ;;
        setup-auto-update)
            manager_handle_self_update --setup-auto-update
            ;;
        remove-auto-update)
            manager_handle_self_update --remove-auto-update
            ;;
        status)
            manager_handle_self_update --self-status
            ;;
            
        # Project management commands
        init)
            shift
            if [ $# -lt 3 ]; then
                echo "Error: init requires name, repo, and script parameters" >&2
                echo "Usage: manager init <name> <repo> <script> [description]" >&2
                exit 1
            fi
            manager_init "$1" "$2" "$3" "$4"
            echo "✅ Project initialized: $1"
            echo "Next: Run 'manager install [options]' to install"
            ;;
        install)
            shift
            if [ -z "$MANAGER_TECH_NAME" ]; then
                echo "Error: No project initialized. Run 'manager init' first." >&2
                exit 1
            fi
            manager_install "$@"
            ;;
        uninstall)
            shift
            if [ -z "$MANAGER_TECH_NAME" ]; then
                echo "Error: No project initialized. Run 'manager init' first." >&2
                exit 1
            fi
            manager_uninstall "$@"
            ;;
        service)
            local action="$2"
            if [ -z "$MANAGER_TECH_NAME" ]; then
                echo "Error: No project initialized. Run 'manager init' first." >&2
                exit 1
            fi
            case "$action" in
                start)
                    manager_start_service
                    ;;
                stop)
                    manager_stop_service
                    ;;
                status)
                    manager_service_status
                    ;;
                *)
                    echo "Error: Unknown service action: $action" >&2
                    echo "Usage: manager service [start|stop|status]" >&2
                    exit 1
                    ;;
            esac
            ;;
        version)
            manager_version
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo "Error: Unknown command: $command" >&2
            echo "Run 'manager help' for usage information" >&2
            exit 1
            ;;
    esac
}

# Run main command
main "$@"