#!/bin/sh
# @akaoio/manager - Universal Shell Framework
# Main entry point and orchestration layer

# Framework version
MANAGER_VERSION="1.0.0"

# Framework directory detection
if [ -z "$MANAGER_DIR" ]; then
    MANAGER_DIR="$(dirname "$0")"
fi

# Load core modules - POSIX compliant
. "$MANAGER_DIR/manager-core.sh"
. "$MANAGER_DIR/manager-config.sh"
. "$MANAGER_DIR/manager-install.sh"
. "$MANAGER_DIR/manager-service.sh"
. "$MANAGER_DIR/manager-update.sh"
. "$MANAGER_DIR/manager-self-update.sh"

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

# Complete installation workflow
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
    
    # Core installation steps
    manager_check_requirements || return 1
    manager_create_xdg_dirs || return 1  
    manager_create_clean_clone || return 1
    manager_install_from_clone || return 1
    
    # Optional components
    if [ "$use_service" = true ]; then
        manager_setup_systemd_service || manager_warn "Failed to setup systemd service"
    fi
    
    if [ "$use_cron" = true ]; then
        manager_setup_cron_job "$cron_interval" || manager_warn "Failed to setup cron job"
    fi
    
    if [ "$use_auto_update" = true ]; then
        manager_setup_auto_update || manager_warn "Failed to setup auto-update"
    fi
    
    # Register this installation for manager self-updates
    manager_register_installation "$(pwd)" "$MANAGER_DIR" || true
    
    manager_log "Installation of $MANAGER_TECH_NAME completed successfully"
    return 0
}

# Setup services (systemd + optional cron backup)
# Usage: manager_setup_service [interval_minutes]
manager_setup_service() {
    local interval="${1:-5}"
    
    if [ -z "$MANAGER_TECH_NAME" ]; then
        manager_error "Manager not initialized"
        return 1
    fi
    
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

# Uninstall technology
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

# Show status of technology
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
    
    # Service status
    echo ""
    echo "🔧 Service Status:"
    manager_service_status
    
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
    echo "Manager Framework v$MANAGER_VERSION"
    echo "Universal POSIX Shell Framework for AKAO Technologies"
}

# Show help
manager_help() {
    cat << 'EOF'
Manager Framework - Universal Shell Framework

Usage:
  Source manager.sh and use these functions:

  manager_init "name" "repo_url" "main_script" ["description"]
  manager_install [--service] [--cron] [--auto-update] [--interval=N]
  manager_setup_service [interval_minutes]
  manager_uninstall [--keep-config] [--keep-data]  
  manager_status
  manager_version
  manager_help

Example:
  #!/bin/sh
  . ./manager.sh
  manager_init "mytool" "https://github.com/user/mytool.git" "mytool.sh"
  manager_install --redundant --auto-update

EOF
}

# Handle self-update commands
if [ $# -gt 0 ]; then
    case "$1" in
        --self-update|--discover|--setup-auto-update|--remove-auto-update|--self-status|--register)
            manager_handle_self_update "$@"
            exit $?
            ;;
    esac
fi

# Functions are available when this file is sourced
# POSIX shells don't support 'export -f', functions are available in current shell context