#!/bin/sh
# @akaoio/manager - Service management functions
# Supports both systemd and cron with intelligent fallback

# Setup systemd service (user or system level)
manager_setup_systemd_service() {
    local service_name="$MANAGER_TECH_NAME"
    local service_desc="$MANAGER_SERVICE_DESCRIPTION"
    local install_dir="$MANAGER_INSTALL_DIR"
    local clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    
    if ! command -v systemctl >/dev/null 2>&1; then
        manager_warn "systemd not available on this system"
        return 1
    fi
    
    manager_log "Setting up systemd service for $service_name..."
    
    # Determine if we should use system or user service
    if sudo -n true 2>/dev/null; then
        manager_setup_system_service
    else
        manager_setup_user_service
    fi
}

# Setup system-level systemd service
manager_setup_system_service() {
    local service_name="$MANAGER_TECH_NAME"
    local service_desc="$MANAGER_SERVICE_DESCRIPTION"
    local install_dir="$MANAGER_INSTALL_DIR"
    local user="$(manager_get_user)"
    local user_home="$(manager_get_user_home)"
    local service_file="/etc/systemd/system/${service_name}.service"
    
    manager_log "Creating system-level service (requires sudo)..."
    
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
    
    manager_log "System-level service created and enabled"
    manager_log "  Commands:"
    manager_log "    Start:   sudo systemctl start $service_name"
    manager_log "    Stop:    sudo systemctl stop $service_name"
    manager_log "    Status:  sudo systemctl status $service_name"
    manager_log "    Logs:    sudo journalctl -u $service_name -f"
    
    return 0
}

# Setup user-level systemd service
manager_setup_user_service() {
    local service_name="$MANAGER_TECH_NAME"
    local service_desc="$MANAGER_SERVICE_DESCRIPTION"
    local install_dir="$MANAGER_INSTALL_DIR"
    local clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    local user_home="$(manager_get_user_home)"
    local systemd_dir="$user_home/.config/systemd/user"
    local service_file="$systemd_dir/${service_name}.service"
    
    manager_log "Creating user-level service (no sudo required)..."
    
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
    
    manager_log "User-level service created and enabled"
    manager_log "  Commands:"
    manager_log "    Start:   systemctl --user start $service_name"
    manager_log "    Stop:    systemctl --user stop $service_name"
    manager_log "    Status:  systemctl --user status $service_name"
    manager_log "    Logs:    journalctl --user -u $service_name -f"
    
    # Enable lingering so service starts at boot
    if command -v loginctl >/dev/null 2>&1; then
        local user="$(manager_get_user)"
        if sudo -n loginctl enable-linger "$user" 2>/dev/null; then
            manager_log "  Boot:    Service will start at boot (lingering enabled)"
        else
            manager_warn "Could not enable user lingering - service won't start at boot without login"
        fi
    fi
    
    return 0
}

# Start systemd service
manager_start_service() {
    local service_name="$MANAGER_TECH_NAME"
    
    if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
        systemctl --user start "$service_name" || return 1
        manager_log "User service started: $service_name"
    elif sudo systemctl is-enabled "$service_name" >/dev/null 2>&1; then
        sudo systemctl start "$service_name" || return 1
        manager_log "System service started: $service_name"
    else
        manager_error "No systemd service found for $service_name"
        return 1
    fi
    
    return 0
}

# Stop systemd service
manager_stop_service() {
    local service_name="$MANAGER_TECH_NAME"
    
    if systemctl --user is-active "$service_name" >/dev/null 2>&1; then
        systemctl --user stop "$service_name" || return 1
        manager_log "User service stopped: $service_name"
    elif sudo systemctl is-active "$service_name" >/dev/null 2>&1; then
        sudo systemctl stop "$service_name" || return 1
        manager_log "System service stopped: $service_name"
    else
        manager_warn "No active systemd service found for $service_name"
        return 1
    fi
    
    return 0
}

# Check systemd service status
manager_service_status() {
    local service_name="$MANAGER_TECH_NAME"
    
    if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
        if systemctl --user is-active "$service_name" >/dev/null 2>&1; then
            echo "  ✅ User service: Active and running"
        else
            echo "  ⚠️ User service: Enabled but not running"
        fi
        echo "  📝 Control: systemctl --user [start|stop|restart|status] $service_name"
    elif [ -f "/etc/systemd/system/${service_name}.service" ]; then
        if sudo systemctl is-active "$service_name" >/dev/null 2>&1; then
            echo "  ✅ System service: Active and running"
        else
            echo "  ⚠️ System service: Enabled but not running"
        fi
        echo "  📝 Control: sudo systemctl [start|stop|restart|status] $service_name"
    else
        echo "  ❌ No systemd service found"
    fi
}

# Disable systemd service
manager_disable_service() {
    local service_name="$MANAGER_TECH_NAME"
    
    if systemctl --user is-enabled "$service_name" >/dev/null 2>&1; then
        systemctl --user stop "$service_name" 2>/dev/null || true
        systemctl --user disable "$service_name" || return 1
        rm -f "$HOME/.config/systemd/user/${service_name}.service"
        systemctl --user daemon-reload
        manager_log "User service disabled and removed"
    fi
    
    if [ -f "/etc/systemd/system/${service_name}.service" ]; then
        sudo systemctl stop "$service_name" 2>/dev/null || true
        sudo systemctl disable "$service_name" || return 1
        sudo rm -f "/etc/systemd/system/${service_name}.service"
        sudo systemctl daemon-reload
        manager_log "System service disabled and removed"
    fi
    
    return 0
}

# Setup cron job
manager_setup_cron_job() {
    local interval="${1:-5}"
    local service_name="$MANAGER_TECH_NAME"
    local install_dir="$MANAGER_INSTALL_DIR"
    
    if ! command -v crontab >/dev/null 2>&1; then
        manager_warn "cron not available on this system"
        return 1
    fi
    
    manager_log "Setting up cron job (every $interval minutes)..."
    
    # Remove any existing cron jobs for this service
    (crontab -l 2>/dev/null | grep -v "$install_dir/$service_name") | crontab - 2>/dev/null || true
    
    # Add new cron job
    local cron_line="*/$interval * * * * $install_dir/$service_name update >/dev/null 2>&1"
    (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
    
    manager_log "Cron job created (runs every $interval minutes)"
    manager_log "  Commands:"
    manager_log "    View:    crontab -l"
    manager_log "    Remove:  crontab -l | grep -v $service_name | crontab -"
    
    return 0
}

# Remove cron job
manager_remove_cron_job() {
    local service_name="$MANAGER_TECH_NAME"
    local install_dir="$MANAGER_INSTALL_DIR"
    
    if ! command -v crontab >/dev/null 2>&1; then
        return 0  # No cron, nothing to remove
    fi
    
    # Remove cron jobs for this service
    (crontab -l 2>/dev/null | grep -v "$install_dir/$service_name") | crontab - 2>/dev/null || true
    
    manager_log "Cron job removed for $service_name"
    return 0
}

# Setup redundant automation (systemd + cron backup)
manager_setup_redundant_automation() {
    local interval="${1:-5}"
    local systemd_success=false
    local cron_success=false
    
    manager_log "Setting up redundant automation (service + cron backup)..."
    
    # Try systemd first
    if manager_setup_systemd_service; then
        systemd_success=true
        manager_log "Primary: systemd service configured"
        
        # Auto-start the service
        if manager_start_service; then
            manager_log "Primary: systemd service started"
        else
            manager_warn "Primary: systemd service failed to start"
        fi
    else
        manager_warn "Primary: systemd service setup failed"
    fi
    
    # Add cron backup if available
    if command -v crontab >/dev/null 2>&1; then
        if manager_setup_cron_job "$interval"; then
            cron_success=true
            manager_log "Backup: cron job configured"
        else
            manager_warn "Backup: cron job setup failed"
        fi
    else
        manager_warn "Backup: cron not available"
    fi
    
    # Report results
    if [ "$systemd_success" = true ] && [ "$cron_success" = true ]; then
        manager_log "✅ REDUNDANT AUTOMATION ENABLED"
        manager_log "  🔄 Systemd service (primary)"
        manager_log "  ⏰ Cron backup every $interval minutes"
        manager_log "  🛡️ When service dies → cron works"
        manager_log "  🛡️ When cron dies → service works"
        return 0
    elif [ "$systemd_success" = true ] || [ "$cron_success" = true ]; then
        manager_log "⚠️ PARTIAL AUTOMATION ENABLED"
        [ "$systemd_success" = true ] && manager_log "  ✅ Systemd service active"
        [ "$cron_success" = true ] && manager_log "  ✅ Cron job active"
        return 0
    else
        manager_error "❌ AUTOMATION SETUP FAILED"
        manager_error "Neither systemd nor cron could be configured"
        return 1
    fi
}