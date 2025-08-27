#!/bin/sh
# @akaoio/manager - Auto-update system functions
# Clean clone maintenance and version management

# Setup auto-update system
manager_setup_auto_update() {
    local service_name="$MANAGER_TECH_NAME"
    local config_dir="$MANAGER_CONFIG_DIR"
    local update_script="$config_dir/auto-update.sh"
    
    manager_log "Setting up auto-update system for $service_name..."
    
    # Create auto-update script
    manager_create_auto_update_script "$update_script" || return 1
    chmod +x "$update_script"
    
    # Add weekly auto-update cron job
    local update_cron="0 3 * * 0 $update_script >/dev/null 2>&1"
    (crontab -l 2>/dev/null | grep -v "auto-update.sh"; echo "$update_cron") | crontab -
    
    manager_log "Auto-update enabled"
    manager_log "  Update script: $update_script"
    manager_log "  Update log: $config_dir/auto-update.log"
    manager_log "  Schedule: Weekly (Sunday 3 AM)"
    
    return 0
}

# Create auto-update script
manager_create_auto_update_script() {
    local script_path="$1"
    local service_name="$MANAGER_TECH_NAME"
    local repo_url="$MANAGER_REPO_URL"
    local clean_clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    local install_dir="$MANAGER_INSTALL_DIR"
    local config_dir="$MANAGER_CONFIG_DIR"
    
    cat > "$script_path" << EOF
#!/bin/sh
# Auto-update script for $service_name
# Maintains clean clone and updates installation

SERVICE_NAME="$service_name"
REPO_URL="$repo_url"
CLEAN_CLONE_DIR="$clean_clone_dir"
INSTALL_DIR="$install_dir"
CONFIG_DIR="$config_dir"
LOG_FILE="\$CONFIG_DIR/auto-update.log"

# Function to log with timestamp
log_update() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$*" >> "\$LOG_FILE"
}

# Function to update clean clone
update_clean_clone() {
    if [ -d "\$CLEAN_CLONE_DIR" ]; then
        cd "\$CLEAN_CLONE_DIR" || {
            log_update "ERROR: Cannot cd to \$CLEAN_CLONE_DIR"
            return 1
        }
        
        # Fetch latest changes
        git fetch origin >/dev/null 2>&1 || {
            log_update "ERROR: git fetch failed"
            return 1
        }
        
        # Check if update needed
        LOCAL=\$(git rev-parse HEAD 2>/dev/null)
        REMOTE=\$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
        
        if [ "\$LOCAL" != "\$REMOTE" ]; then
            # POSIX-compliant hash display
            LOCAL_SHORT=\$(echo "\$LOCAL" | cut -c1-8)
            REMOTE_SHORT=\$(echo "\$REMOTE" | cut -c1-8)
            log_update "Updates available (\$LOCAL_SHORT -> \$REMOTE_SHORT)"
            
            # Create backup of current version
            BACKUP_DIR="\$CONFIG_DIR/backups/\$(date +%Y%m%d-%H%M%S)"
            mkdir -p "\$BACKUP_DIR"
            cp -r "\$CLEAN_CLONE_DIR" "\$BACKUP_DIR/" 2>/dev/null || true
            
            # Pull updates
            git reset --hard "\$REMOTE" >/dev/null 2>&1 || {
                log_update "ERROR: git reset failed"
                return 1
            }
            
            log_update "Clean clone updated successfully"
            return 0
        else
            # POSIX-compliant hash display
            LOCAL_SHORT=\$(echo "\$LOCAL" | cut -c1-8)
            log_update "No updates needed (\$LOCAL_SHORT)"
            return 1
        fi
    else
        # Clone if directory doesn't exist
        log_update "Clean clone missing, creating \$CLEAN_CLONE_DIR"
        git clone "\$REPO_URL" "\$CLEAN_CLONE_DIR" >/dev/null 2>&1 || {
            log_update "ERROR: git clone failed"
            return 1
        }
        log_update "Clean clone created successfully"
        return 0
    fi
}

# Function to update installation
update_installation() {
    log_update "Updating installation..."
    
    # Run the manager installation process
    # This recreates the installation from the updated clean clone
    MANAGER_DIR="\$(dirname "\$0")/../manager"
    if [ -f "\$MANAGER_DIR/manager.sh" ]; then
        . "\$MANAGER_DIR/manager.sh"
        manager_init "\$SERVICE_NAME" "\$REPO_URL" "$MANAGER_MAIN_SCRIPT" "$MANAGER_SERVICE_DESCRIPTION"
        manager_install_from_clone || {
            log_update "ERROR: Installation update failed"
            return 1
        }
    else
        log_update "ERROR: Manager framework not found"
        return 1
    fi
    
    log_update "Installation updated successfully"
    return 0
}

# Function to restart services
restart_services() {
    # Restart systemd service if it exists
    if systemctl --user is-enabled "\$SERVICE_NAME" >/dev/null 2>&1; then
        systemctl --user restart "\$SERVICE_NAME" >/dev/null 2>&1 && \
        log_update "User service restarted successfully"
    elif systemctl is-enabled "\$SERVICE_NAME" >/dev/null 2>&1; then
        sudo systemctl restart "\$SERVICE_NAME" >/dev/null 2>&1 && \
        log_update "System service restarted successfully"
    fi
}

# Function to verify update
verify_update() {
    local binary="\$INSTALL_DIR/\$SERVICE_NAME"
    
    if [ -f "\$binary" ] && [ -x "\$binary" ]; then
        if "\$binary" --version >/dev/null 2>&1 || "\$binary" version >/dev/null 2>&1; then
            log_update "Update verification successful"
            return 0
        else
            log_update "WARNING: Update verification failed (version check)"
            return 1
        fi
    else
        log_update "ERROR: Update verification failed (binary missing or not executable)"
        return 1
    fi
}

# Function to rollback on failure
rollback_update() {
    log_update "Rolling back due to verification failure..."
    
    # Find most recent backup
    BACKUP_BASE="\$CONFIG_DIR/backups"
    if [ -d "\$BACKUP_BASE" ]; then
        LATEST_BACKUP=\$(ls -1t "\$BACKUP_BASE" | head -1)
        if [ -n "\$LATEST_BACKUP" ] && [ -d "\$BACKUP_BASE/\$LATEST_BACKUP" ]; then
            log_update "Restoring from backup: \$LATEST_BACKUP"
            rm -rf "\$CLEAN_CLONE_DIR"
            cp -r "\$BACKUP_BASE/\$LATEST_BACKUP/\$(basename "\$CLEAN_CLONE_DIR")" "\$CLEAN_CLONE_DIR"
            update_installation
            log_update "Rollback completed"
            return 0
        fi
    fi
    
    log_update "ERROR: No backup available for rollback"
    return 1
}

# Main update process
if update_clean_clone; then
    if update_installation; then
        if verify_update; then
            restart_services
            log_update "Auto-update completed successfully"
        else
            rollback_update
        fi
    else
        log_update "ERROR: Installation update failed"
    fi
fi

# Cleanup old backups (keep last 5)
BACKUP_BASE="\$CONFIG_DIR/backups"
if [ -d "\$BACKUP_BASE" ]; then
    ls -1t "\$BACKUP_BASE" | tail -n +6 | while read -r old_backup; do
        if [ -d "\$BACKUP_BASE/\$old_backup" ]; then
            rm -rf "\$BACKUP_BASE/\$old_backup"
            log_update "Cleaned up old backup: \$old_backup"
        fi
    done
fi
EOF
    
    return 0
}

# Manual update check and execution
manager_check_updates() {
    local clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    local current_hash remote_hash
    
    if [ ! -d "$clone_dir" ]; then
        manager_error "Clean clone not found: $clone_dir"
        return 1
    fi
    
    manager_log "Checking for updates..."
    
    cd "$clone_dir" || return 1
    git fetch origin >/dev/null 2>&1 || {
        manager_error "Failed to fetch from remote repository"
        return 1
    }
    
    current_hash=$(git rev-parse HEAD 2>/dev/null)
    remote_hash=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
    
    if [ "$current_hash" != "$remote_hash" ]; then
        manager_log "Updates available:"
        manager_log "  Current: ${current_hash:0:8}"
        manager_log "  Remote:  ${remote_hash:0:8}"
        return 0
    else
        manager_log "Already up to date (${current_hash:0:8})"
        return 1
    fi
}

# Apply updates manually
manager_apply_updates() {
    local clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    local config_dir="$MANAGER_CONFIG_DIR"
    
    if ! manager_check_updates >/dev/null 2>&1; then
        manager_log "No updates available"
        return 0
    fi
    
    manager_log "Applying updates..."
    
    # Create backup
    local backup_dir="$config_dir/backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r "$clone_dir" "$backup_dir/" || {
        manager_warn "Failed to create backup"
    }
    
    # Apply updates
    cd "$clone_dir" || return 1
    local remote_hash
    remote_hash=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
    git reset --hard "$remote_hash" >/dev/null 2>&1 || {
        manager_error "Failed to apply updates"
        return 1
    }
    
    # Reinstall from updated clone
    if manager_install_from_clone; then
        manager_log "Updates applied successfully"
        
        # Restart services if they exist
        manager_stop_service 2>/dev/null || true
        manager_start_service 2>/dev/null || true
        
        return 0
    else
        manager_error "Failed to reinstall after update"
        return 1
    fi
}

# Remove auto-update system
manager_remove_auto_update() {
    local service_name="$MANAGER_TECH_NAME"
    local config_dir="$MANAGER_CONFIG_DIR"
    
    manager_log "Removing auto-update system..."
    
    # Remove cron job
    (crontab -l 2>/dev/null | grep -v "auto-update.sh") | crontab - 2>/dev/null || true
    
    # Remove auto-update script
    rm -f "$config_dir/auto-update.sh"
    
    # Remove backups
    rm -rf "$config_dir/backups"
    
    manager_log "Auto-update system removed"
    return 0
}