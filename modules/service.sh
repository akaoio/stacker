#!/bin/sh
# Module: service
# Description: Service management functions with systemd and cron support
# Dependencies: core config
# Provides: systemd services, cron jobs, service lifecycle management

# Module metadata
STACKER_MODULE_NAME="service"
STACKER_MODULE_VERSION="1.0.0"
STACKER_MODULE_DEPENDENCIES="core config"
STACKER_MODULE_LOADED=false

# Module initialization
service_init() {
    STACKER_MODULE_LOADED=true
    stacker_debug "Service module initialized"
    return 0
}

# Setup systemd service (user or system level)
stacker_setup_systemd_service() {
    local service_name="$STACKER_TECH_NAME"
    local service_desc="$STACKER_SERVICE_DESCRIPTION"
    local install_dir="$STACKER_INSTALL_DIR"
    local clone_dir="$STACKER_CLEAN_CLONE_DIR"
    
    if ! command -v systemctl >/dev/null 2>&1; then
        stacker_warn "systemd not available on this system"
        return 1
    fi
    
    stacker_log "Setting up systemd service for $service_name..."
    
    # Determine if we should use system or user service
    if sudo -n true 2>/dev/null; then
        stacker_setup_system_service
    else
        stacker_setup_user_service
    fi
}

# Setup system-level systemd service
stacker_setup_system_service() {
    local service_name="$STACKER_TECH_NAME"
    local service_desc="$STACKER_SERVICE_DESCRIPTION"
    local install_dir="$STACKER_INSTALL_DIR"
    local user="$(stacker_get_user)"
    local user_home="$(stacker_get_user_home)"
    local service_file="/etc/systemd/system/${service_name}.service"
    
    stacker_log "Creating system-level service (requires sudo)..."
    
    # Create service file
    sudo tee "$service_file" >/dev/null << EOF
[Unit]
Description=$service_desc
After=network.target network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$user
Environment="HOME=$user_home"
Environment="XDG_CONFIG_HOME=$user_home/.config"
Environment="XDG_DATA_HOME=$user_home/.local/share"
Environment="XDG_STATE_HOME=$user_home/.local/state"
ExecStart=$install_dir/$service_name daemon
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$user_home/.config/$service_name $user_home/.local/share/$service_name $user_home/.local/state/$service_name

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload and enable service
    sudo systemctl daemon-reload || return 1
    sudo systemctl enable "$service_name" || return 1
    
    stacker_log "System-level service created and enabled"
    stacker_log "  Commands:"
    stacker_log "    Start:   sudo systemctl start $service_name"
    stacker_log "    Stop:    sudo systemctl stop $service_name"
    stacker_log "    Status:  sudo systemctl status $service_name"
    stacker_log "    Logs:    sudo journalctl -u $service_name -f"
    
    return 0
}

# Setup user-level systemd service
stacker_setup_user_service() {
    local service_name="$STACKER_TECH_NAME"
    local service_desc="$STACKER_SERVICE_DESCRIPTION"
    local install_dir="$STACKER_INSTALL_DIR"
    local clone_dir="$STACKER_CLEAN_CLONE_DIR"
    local user_home="$(stacker_get_user_home)"
    local systemd_dir="$user_home/.config/systemd/user"
    local service_file="$systemd_dir/${service_name}.service"
    
    stacker_log "Creating user-level service (no sudo required)..."
    
    # Create user systemd directory
    mkdir -p "$systemd_dir" || return 1
    
    # Determine ExecStart based on application type
    local exec_start
    if [ -f "$clone_dir/package.json" ]; then
        # Node.js application
        exec_start="$install_dir/$service_name"
    else
        # Shell script or binary
        exec_start="$install_dir/$service_name daemon"
    fi
    
    # Create service file
    cat > "$service_file" << EOF
[Unit]
Description=$service_desc (User Service)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Environment="HOME=$user_home"
Environment="XDG_CONFIG_HOME=$user_home/.config"
Environment="XDG_DATA_HOME=$user_home/.local/share"
Environment="XDG_STATE_HOME=$user_home/.local/state"
ExecStart=$exec_start
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
    
    # Reload user systemd and enable service
    systemctl --user daemon-reload || return 1
    systemctl --user enable "$service_name" || return 1
    
    stacker_log "User-level service created and enabled"
    stacker_log "  Commands:"
    stacker_log "    Start:   systemctl --user start $service_name"
    stacker_log "    Stop:    systemctl --user stop $service_name"
    stacker_log "    Status:  systemctl --user status $service_name"
    stacker_log "    Logs:    journalctl --user -u $service_name -f"
    
    # Enable lingering so service starts at boot
    if command -v loginctl >/dev/null 2>&1; then
        local user="$(stacker_get_user)"
        if sudo -n loginctl enable-linger "$user" 2>/dev/null; then
            stacker_log "  Boot:    Service will start at boot (lingering enabled)"
        else
            stacker_warn "Could not enable user lingering - service won't start at boot without login"
        fi
    fi
    
    return 0
}

# Setup cron job
stacker_setup_cron_job() {
    local interval="${1:-5}"
    local service_name="$STACKER_TECH_NAME"
    local install_dir="$STACKER_INSTALL_DIR"
    local binary_path="$install_dir/$service_name"
    local cron_comment="# $service_name - managed by Stacker framework"
    local cron_entry
    
    if ! command -v crontab >/dev/null 2>&1; then
        stacker_warn "cron not available on this system"
        return 1
    fi
    
    stacker_log "Setting up cron job for $service_name (interval: ${interval}m)..."
    
    # Create cron entry
    cron_entry="*/$interval * * * * $binary_path update >/dev/null 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$service_name"; then
        stacker_log "Updating existing cron job..."
        # Remove existing entries and add new one
        (crontab -l 2>/dev/null | grep -v "$service_name"; echo "$cron_comment"; echo "$cron_entry") | crontab -
    else
        stacker_log "Adding new cron job..."
        # Add new entry
        (crontab -l 2>/dev/null; echo "$cron_comment"; echo "$cron_entry") | crontab -
    fi
    
    stacker_log "Cron job configured successfully"
    stacker_log "  Entry: $cron_entry"
    stacker_log "  View:  crontab -l | grep $service_name"
    
    return 0
}

# Remove cron job
stacker_remove_cron_job() {
    local service_name="$STACKER_TECH_NAME"
    
    if ! command -v crontab >/dev/null 2>&1; then
        return 0
    fi
    
    stacker_log "Removing cron job for $service_name..."
    
    # Remove entries related to this service
    if crontab -l 2>/dev/null | grep -q "$service_name"; then
        crontab -l 2>/dev/null | grep -v "$service_name" | crontab -
        stacker_log "Cron job removed successfully"
    else
        stacker_debug "No cron job found to remove"
    fi
    
    return 0
}

# Service control functions
stacker_start_service() {
    local service_name="$STACKER_TECH_NAME"
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
            systemctl --user start "$service_name"
        elif sudo -n systemctl is-enabled "$service_name" >/dev/null 2>&1; then
            sudo systemctl start "$service_name"
        else
            stacker_error "No systemd service found for $service_name"
            return 1
        fi
    else
        stacker_error "Service management requires systemd"
        return 1
    fi
}

stacker_stop_service() {
    local service_name="$STACKER_TECH_NAME"
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
            systemctl --user stop "$service_name"
        elif sudo -n systemctl is-enabled "$service_name" >/dev/null 2>&1; then
            sudo systemctl stop "$service_name"
        else
            stacker_error "No systemd service found for $service_name"
            return 1
        fi
    else
        stacker_error "Service management requires systemd"
        return 1
    fi
}

stacker_restart_service() {
    local service_name="$STACKER_TECH_NAME"
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
            systemctl --user restart "$service_name"
        elif sudo -n systemctl is-enabled "$service_name" >/dev/null 2>&1; then
            sudo systemctl restart "$service_name"
        else
            stacker_error "No systemd service found for $service_name"
            return 1
        fi
    else
        stacker_error "Service management requires systemd"
        return 1
    fi
}

stacker_service_status() {
    local service_name="$STACKER_TECH_NAME"
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
            echo "🔧 User Service:"
            systemctl --user status "$service_name" --no-pager -l
        elif sudo -n systemctl is-enabled "$service_name" >/dev/null 2>&1; then
            echo "🔧 System Service:"
            sudo systemctl status "$service_name" --no-pager -l
        else
            echo "❌ No systemd service configured"
        fi
    else
        echo "❌ systemd not available"
    fi
}

stacker_enable_service() {
    local service_name="$STACKER_TECH_NAME"
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user list-unit-files | grep -q "$service_name"; then
            systemctl --user enable "$service_name"
        elif sudo systemctl list-unit-files | grep -q "$service_name"; then
            sudo systemctl enable "$service_name"
        else
            stacker_error "No systemd service found for $service_name"
            return 1
        fi
    else
        stacker_error "Service management requires systemd"
        return 1
    fi
}

stacker_disable_service() {
    local service_name="$STACKER_TECH_NAME"
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
            systemctl --user disable "$service_name"
            systemctl --user stop "$service_name" 2>/dev/null || true
        elif sudo -n systemctl is-enabled "$service_name" >/dev/null 2>&1; then
            sudo systemctl disable "$service_name"
            sudo systemctl stop "$service_name" 2>/dev/null || true
        else
            stacker_debug "No systemd service found to disable"
        fi
    else
        stacker_debug "systemd not available for service management"
    fi
}

# Export public interface
service_list_functions() {
    echo "stacker_setup_systemd_service stacker_setup_system_service stacker_setup_user_service"
    echo "stacker_setup_cron_job stacker_remove_cron_job"
    echo "stacker_start_service stacker_stop_service stacker_restart_service stacker_service_status"
    echo "stacker_enable_service stacker_disable_service"
}