#!/bin/sh
# @akaoio/manager - Self-update system for manager framework
# POSIX compliant and XDG Base Directory compliant

# Manager self-update configuration - XDG compliant
MANAGER_REPO_URL="https://github.com/akaoio/manager.git"
MANAGER_XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
MANAGER_XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
MANAGER_VERSION_FILE="$MANAGER_XDG_CONFIG_HOME/manager/version"
MANAGER_REGISTRY_FILE="$MANAGER_XDG_CONFIG_HOME/manager/installations"
MANAGER_SELF_UPDATE_LOG="$MANAGER_XDG_DATA_HOME/manager/self-update.log"

# Logging for self-update - XDG and POSIX compliant
manager_self_log() {
    printf "[Manager Self-Update] %s\n" "$*"
    # Ensure log directory exists
    mkdir -p "$(dirname "$MANAGER_SELF_UPDATE_LOG")" 2>/dev/null || true
    printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$MANAGER_SELF_UPDATE_LOG" 2>/dev/null || true
}

# Register a project that uses manager
manager_register_installation() {
    local project_path="$1"
    local manager_path="$2"
    
    if [ -z "$project_path" ] || [ -z "$manager_path" ]; then
        manager_error "manager_register_installation requires project_path and manager_path"
        return 1
    fi
    
    # Create registry directory
    mkdir -p "$(dirname "$MANAGER_REGISTRY_FILE")" || return 1
    
    # Add to registry (avoid duplicates) - POSIX compliant
    local entry="$project_path:$manager_path"
    if [ ! -f "$MANAGER_REGISTRY_FILE" ] || ! grep -Fxq "$entry" "$MANAGER_REGISTRY_FILE" 2>/dev/null; then
        printf "%s\n" "$entry" >> "$MANAGER_REGISTRY_FILE"
        manager_self_log "Registered installation: $entry"
    fi
}

# Discover manager installations automatically - POSIX compliant
manager_discover_installations() {
    local search_paths="$HOME"
    local discovered_count=0
    
    # Add common project directories if they exist
    for path in "$HOME/projects" "$HOME/src" "$HOME/code" "/opt" "/usr/local/src"; do
        if [ -d "$path" ]; then
            search_paths="$search_paths $path"
        fi
    done
    
    manager_self_log "Discovering manager installations..."
    
    # Search for manager.sh files - POSIX compliant find usage
    for base_path in $search_paths; do
        if [ -d "$base_path" ]; then
            # Use find with POSIX-compliant options
            find "$base_path" -name "manager.sh" -type f 2>/dev/null | while IFS= read -r manager_file; do
                manager_dir="$(dirname "$manager_file")"
                project_dir="$(dirname "$manager_dir")"
                
                # Verify it's actually a manager framework by checking for version
                if grep -q "MANAGER_VERSION" "$manager_file" 2>/dev/null; then
                    manager_register_installation "$project_dir" "$manager_dir"
                    discovered_count=$((discovered_count + 1))
                fi
            done
        fi
    done
    
    manager_self_log "Discovery complete"
}

# Check if manager framework needs updating - POSIX compliant
manager_check_self_update() {
    local current_version latest_version
    
    # Get current version
    if [ -f "$MANAGER_VERSION_FILE" ]; then
        current_version=$(cat "$MANAGER_VERSION_FILE" 2>/dev/null)
    fi
    current_version="${current_version:-unknown}"
    
    # Check latest version from repository - more robust version check
    if command -v git >/dev/null 2>&1; then
        # Try tags first
        latest_version=$(git ls-remote --tags "$MANAGER_REPO_URL" 2>/dev/null | \
                        grep -E 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | \
                        sed 's/.*refs\/tags\/v//' | \
                        sort -t. -k1,1n -k2,2n -k3,3n | \
                        tail -1)
        
        if [ -z "$latest_version" ]; then
            # Fallback to commit hash from main branch
            latest_version=$(git ls-remote "$MANAGER_REPO_URL" main 2>/dev/null | cut -c1-8)
        fi
    fi
    
    if [ -z "$latest_version" ]; then
        manager_self_log "Warning: Could not determine latest version"
        return 1
    fi
    
    manager_self_log "Version check: current=$current_version, latest=$latest_version"
    
    if [ "$current_version" != "$latest_version" ]; then
        return 0  # Update needed
    else
        return 1  # Up to date
    fi
}

# Update manager framework in a specific location - POSIX compliant
manager_update_installation() {
    local project_path="$1"
    local manager_path="$2"
    local temp_dir backup_dir
    
    if [ ! -d "$project_path" ] || [ ! -d "$manager_path" ]; then
        manager_self_log "ERROR: Invalid paths - project: $project_path, manager: $manager_path"
        return 1
    fi
    
    manager_self_log "Updating manager in: $project_path"
    
    # Create temporary directory for new version - POSIX compliant
    if command -v mktemp >/dev/null 2>&1; then
        temp_dir=$(mktemp -d 2>/dev/null) || temp_dir=""
    fi
    if [ -z "$temp_dir" ]; then
        temp_dir="/tmp/manager-update.$$"
        mkdir "$temp_dir" || return 1
    fi
    
    backup_dir="$manager_path.backup.$(date +%Y%m%d-%H%M%S)"
    
    # Clone latest manager version
    if ! git clone --depth 1 "$MANAGER_REPO_URL" "$temp_dir/manager" >/dev/null 2>&1; then
        manager_self_log "ERROR: Failed to clone manager repository"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Create backup of existing manager
    if ! cp -r "$manager_path" "$backup_dir"; then
        manager_self_log "ERROR: Failed to create backup"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Replace manager framework
    if ! rm -rf "$manager_path" || ! mv "$temp_dir/manager" "$manager_path"; then
        manager_self_log "ERROR: Failed to replace manager, restoring backup"
        rm -rf "$manager_path" 2>/dev/null || true
        mv "$backup_dir" "$manager_path"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify update
    if [ -f "$manager_path/manager.sh" ]; then
        manager_self_log "Successfully updated manager in $project_path"
        rm -rf "$backup_dir" "$temp_dir"
        return 0
    else
        manager_self_log "ERROR: Update verification failed, restoring backup"
        rm -rf "$manager_path" 2>/dev/null || true
        mv "$backup_dir" "$manager_path"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Update all registered manager installations - POSIX compliant
manager_update_all_installations() {
    local updated=0 failed=0 total=0
    local project_path manager_path
    
    if [ ! -f "$MANAGER_REGISTRY_FILE" ]; then
        manager_self_log "No installations registered, running discovery..."
        manager_discover_installations
    fi
    
    if [ ! -f "$MANAGER_REGISTRY_FILE" ]; then
        manager_self_log "No manager installations found"
        return 1
    fi
    
    manager_self_log "Starting bulk update of all manager installations"
    
    # POSIX compliant file reading
    while IFS=':' read -r project_path manager_path || [ -n "$project_path" ]; do
        # Skip empty lines
        [ -n "$project_path" ] || continue
        
        total=$((total + 1))
        
        if manager_update_installation "$project_path" "$manager_path"; then
            updated=$((updated + 1))
        else
            failed=$((failed + 1))
        fi
    done < "$MANAGER_REGISTRY_FILE"
    
    manager_self_log "Update complete: $updated updated, $failed failed, $total total"
    
    # Update version file if all updates succeeded
    if [ "$failed" -eq 0 ] && [ "$updated" -gt 0 ]; then
        local latest_version
        if command -v git >/dev/null 2>&1; then
            latest_version=$(git ls-remote --tags "$MANAGER_REPO_URL" 2>/dev/null | \
                            grep -E 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | \
                            sed 's/.*refs\/tags\/v//' | \
                            sort -t. -k1,1n -k2,2n -k3,3n | \
                            tail -1)
            if [ -n "$latest_version" ]; then
                mkdir -p "$(dirname "$MANAGER_VERSION_FILE")"
                printf "%s\n" "$latest_version" > "$MANAGER_VERSION_FILE"
            fi
        fi
    fi
    
    return "$failed"
}

# Setup automatic self-update cron job - POSIX compliant
manager_setup_self_update_cron() {
    local script_path cron_line
    
    # Determine the script path for the cron job
    if [ -f "$0" ]; then
        script_path="$0"
    elif [ -f "$(dirname "$0")/manager.sh" ]; then
        script_path="$(dirname "$0")/manager.sh"
    else
        manager_self_log "ERROR: Cannot determine script path for cron job"
        return 1
    fi
    
    cron_line="0 4 * * 1 $script_path --self-update >/dev/null 2>&1"
    
    manager_self_log "Setting up weekly self-update cron job..."
    
    # Remove existing self-update cron - POSIX compliant
    if command -v crontab >/dev/null 2>&1; then
        (crontab -l 2>/dev/null | grep -v "manager.*--self-update" || true) | crontab - 2>/dev/null || true
        
        # Add new self-update cron (Monday 4 AM)
        (crontab -l 2>/dev/null || true; printf "%s\n" "$cron_line") | crontab -
        
        manager_self_log "Self-update cron job created (Monday 4 AM)"
    else
        manager_self_log "ERROR: crontab command not available"
        return 1
    fi
}

# Remove self-update system - XDG compliant cleanup
manager_remove_self_update() {
    manager_self_log "Removing self-update system..."
    
    # Remove cron job
    if command -v crontab >/dev/null 2>&1; then
        (crontab -l 2>/dev/null | grep -v "manager.*--self-update" || true) | crontab - 2>/dev/null || true
    fi
    
    # Remove registry and config files
    rm -f "$MANAGER_REGISTRY_FILE" "$MANAGER_VERSION_FILE" 2>/dev/null || true
    rm -f "$MANAGER_SELF_UPDATE_LOG" 2>/dev/null || true
    
    # Clean up empty directories
    rmdir "$(dirname "$MANAGER_REGISTRY_FILE")" 2>/dev/null || true
    rmdir "$(dirname "$MANAGER_SELF_UPDATE_LOG")" 2>/dev/null || true
    
    manager_self_log "Self-update system removed"
}

# Show self-update status - POSIX compliant
manager_self_update_status() {
    local current_version installations
    
    printf "==========================================\n"
    printf "  Manager Framework Self-Update Status\n"
    printf "==========================================\n"
    printf "\n"
    
    # Current version
    if [ -f "$MANAGER_VERSION_FILE" ]; then
        current_version=$(cat "$MANAGER_VERSION_FILE" 2>/dev/null)
        printf "Current Version: %s\n" "${current_version:-Unknown}"
    else
        printf "Current Version: Unknown (run discovery)\n"
    fi
    
    # Check if updates available
    if manager_check_self_update >/dev/null 2>&1; then
        printf "Update Status: ⚠️  Updates available\n"
    else
        printf "Update Status: ✅ Up to date\n"
    fi
    
    # Registered installations
    if [ -f "$MANAGER_REGISTRY_FILE" ]; then
        installations=$(wc -l < "$MANAGER_REGISTRY_FILE" 2>/dev/null || echo "0")
        printf "Installations: %s registered\n" "$installations"
        printf "\n"
        printf "Registered installations:\n"
        
        while IFS=':' read -r project_path manager_path || [ -n "$project_path" ]; do
            [ -n "$project_path" ] || continue
            if [ -f "$manager_path/manager.sh" ]; then
                printf "  ✅ %s\n" "$project_path"
            else
                printf "  ❌ %s (missing)\n" "$project_path"
            fi
        done < "$MANAGER_REGISTRY_FILE"
    else
        printf "Installations: None registered (run discovery)\n"
    fi
    
    # Cron status
    if command -v crontab >/dev/null 2>&1 && crontab -l 2>/dev/null | grep -q "manager.*--self-update"; then
        printf "\n"
        printf "Auto-update: ✅ Enabled (weekly)\n"
    else
        printf "\n"
        printf "Auto-update: ❌ Disabled\n"
    fi
    
    printf "\n"
}

# Main self-update command handler - POSIX compliant
manager_handle_self_update() {
    local command="$1"
    
    case "$command" in
        --self-update|--update-self)
            if manager_check_self_update; then
                manager_self_log "Updates available, starting self-update..."
                manager_update_all_installations
            else
                manager_self_log "No updates needed"
            fi
            ;;
        --discover)
            manager_discover_installations
            ;;
        --setup-auto-update)
            manager_setup_self_update_cron
            ;;
        --remove-auto-update)
            manager_remove_self_update
            ;;
        --self-status)
            manager_self_update_status
            ;;
        --register)
            shift
            manager_register_installation "$1" "$2"
            ;;
        *)
            printf "Manager Self-Update Commands:\n"
            printf "\n"
            printf "  --self-update          Update all manager installations\n"
            printf "  --discover             Discover manager installations\n"
            printf "  --setup-auto-update    Enable weekly auto-updates\n"
            printf "  --remove-auto-update   Remove self-update system\n"
            printf "  --self-status          Show self-update status\n"
            printf "  --register PATH MGR    Register installation manually\n"
            printf "\n"
            ;;
    esac
}