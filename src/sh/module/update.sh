#!/bin/sh
# Stacker Update Module  
# Update and rollback functionality

# Module metadata
STACKER_MODULE_NAME="update"
STACKER_MODULE_VERSION="1.0.0"

# Update command - updates the application
stacker_cli_update() {
    local target="$1"
    
    # Handle different update scenarios
    if [ -z "$target" ]; then
        # Update everything: framework + all packages
        echo "Updating Stacker framework and all packages..."
        stacker_update_framework
        echo "Updating all packages..."
        stacker_require "package" || return 1
        stacker_update_all_packages
    elif [ "$target" = "stacker" ]; then
        # Update framework only
        shift
        local force=false
        local check_only=false
        
        while [ $# -gt 0 ]; do
            case "$1" in
                --check) check_only=true; shift ;;
                --force) force=true; shift ;;
                *) echo "Unknown option: $1"; return 1 ;;
            esac
        done
        
        if [ "$check_only" = true ]; then
            stacker_framework_update_check
        else
            stacker_update_framework "$force"
        fi
    else
        # Update specific package
        shift
        stacker_require "package" || return 1
        stacker_update_package "$target" "$@"
    fi
}

# Update Stacker framework itself
stacker_update_framework() {
    local force="$1"
    
    echo "🔄 Updating Stacker framework..."
    
    # Check if we're in a git repository
    if [ -d "$STACKER_DIR/.git" ]; then
        echo "Updating from git repository..."
        cd "$STACKER_DIR" || return 1
        git pull origin main || {
            echo "❌ Failed to update framework"
            return 1
        }
        echo "✅ Framework updated successfully"
    else
        echo "Downloading latest framework..."
        # Download entire repository and install
        local tmpdir
        tmpdir=$(mktemp -d) || {
            echo "❌ Failed to create temporary directory"
            return 1
        }
        
        cd "$tmpdir" || return 1
        git clone https://github.com/akaoio/stacker.git || {
            echo "❌ Failed to download framework"
            rm -rf "$tmpdir"
            return 1
        }
        
        cd stacker && echo "yes" | ./install.sh || {
            echo "❌ Failed to install framework"
            rm -rf "$tmpdir"
            return 1
        }
        
        rm -rf "$tmpdir"
        echo "✅ Framework updated successfully"
    fi
}

# Check if framework update is available
stacker_framework_update_check() {
    echo "🔍 Checking for framework updates..."
    
    if [ -d "$STACKER_DIR/.git" ]; then
        cd "$STACKER_DIR" || return 1
        git fetch origin main >/dev/null 2>&1
        local local_hash remote_hash
        local_hash=$(git rev-parse HEAD)
        remote_hash=$(git rev-parse origin/main)
        
        if [ "$local_hash" != "$remote_hash" ]; then
            echo "📦 Framework update available"
            echo "Current: $local_hash"
            echo "Latest:  $remote_hash"
        else
            echo "✅ Framework is up to date"
        fi
    else
        echo "📦 Framework update check requires git repository"
    fi
}

# Update all packages
stacker_update_all_packages() {
    echo "🔄 Updating all packages..."
    
    stacker_require "package" || return 1
    local updated=0
    
    # Update packages in all scopes
    for scope in user system local; do
        local pkg_dir="$(stacker_get_package_dirs "$scope")"
        if [ -d "$pkg_dir" ]; then
            for pkg_path in "$pkg_dir"/*; do
                if [ -d "$pkg_path" ] && [ -d "$pkg_path/.git" ]; then
                    local pkg_name="$(basename "$pkg_path")"
                    echo "Updating $pkg_name..."
                    cd "$pkg_path"
                    if git pull origin main >/dev/null 2>&1 || git pull origin master >/dev/null 2>&1; then
                        echo "✅ $pkg_name updated"
                        updated=$((updated + 1))
                    else
                        echo "⚠️ Failed to update $pkg_name"
                    fi
                fi
            done
        fi
    done
    
    if [ $updated -eq 0 ]; then
        echo "No packages to update"
    else
        echo "✅ Updated $updated packages"
    fi
}

# Update specific package
stacker_update_package() {
    local package="$1"
    
    if [ -z "$package" ]; then
        stacker_error "Package name required"
        return 1
    fi
    
    stacker_require "package" || return 1
    
    # Find the package in all scopes
    for scope in user system local; do
        local pkg_dir="$(stacker_get_package_dirs "$scope")"
        local pkg_path="$pkg_dir/$package"
        
        if [ -d "$pkg_path" ]; then
            echo "🔄 Updating package: $package (in $scope scope)"
            
            if [ -d "$pkg_path/.git" ]; then
                cd "$pkg_path"
                if git pull origin main >/dev/null 2>&1 || git pull origin master >/dev/null 2>&1; then
                    echo "✅ Package $package updated successfully"
                    return 0
                else
                    stacker_error "Failed to update $package"
                    return 1
                fi
            else
                stacker_error "Package $package is not a git repository"
                return 1
            fi
        fi
    done
    
    stacker_error "Package $package not found"
    return 1
}

# Check for updates
stacker_update_check() {
    stacker_log "Checking for updates..."
    
    # Check if this is a git repository
    if [ -d ".git" ]; then
        stacker_update_check_git
    elif [ -f "stacker.yaml" ]; then
        stacker_update_check_manifest
    else
        stacker_error "Cannot determine update method (no .git or stacker.yaml)"
        return 1
    fi
}

# Check git-based updates
stacker_update_check_git() {
    local current_commit current_branch remote_commit
    
    # Get current information
    current_commit=$(git rev-parse HEAD 2>/dev/null) || {
        stacker_error "Failed to get current commit"
        return 1
    }
    
    current_branch=$(git branch --show-current 2>/dev/null) || {
        stacker_error "Failed to get current branch"
        return 1
    }
    
    stacker_log "Current branch: $current_branch"
    stacker_log "Current commit: ${current_commit:0:8}"
    
    # Fetch latest changes
    stacker_log "Fetching latest changes..."
    git fetch origin "$current_branch" 2>/dev/null || {
        stacker_warn "Failed to fetch from origin"
        return 1
    }
    
    # Get remote commit
    remote_commit=$(git rev-parse "origin/$current_branch" 2>/dev/null) || {
        stacker_error "Failed to get remote commit"
        return 1
    }
    
    stacker_log "Remote commit: ${remote_commit:0:8}"
    
    # Compare commits
    if [ "$current_commit" = "$remote_commit" ]; then
        stacker_log "✅ No updates available (already up to date)"
        return 0
    else
        stacker_log "📦 Updates available"
        
        # Show what would be updated
        local commit_count
        commit_count=$(git rev-list --count "$current_commit..$remote_commit" 2>/dev/null)
        stacker_log "  $commit_count new commits available"
        
        # Show recent commits
        stacker_log "\nRecent changes:"
        git log --oneline --max-count=5 "$current_commit..$remote_commit" 2>/dev/null | \
            sed 's/^/  /' || true
        
        return 1  # Updates available
    fi
}

# Check manifest-based updates
stacker_update_check_manifest() {
    local current_version remote_version repository
    
    # Get current version
    current_version=$(grep '^version:' stacker.yaml 2>/dev/null | cut -d'"' -f2) || {
        stacker_error "Cannot read current version from stacker.yaml"
        return 1
    }
    
    # Get repository URL
    repository=$(grep '^repository:' stacker.yaml 2>/dev/null | cut -d'"' -f2) || {
        stacker_warn "No repository URL in manifest"
        return 1
    }
    
    stacker_log "Current version: $current_version"
    stacker_log "Repository: $repository"
    
    # For GitHub repositories, check releases
    case "$repository" in
        https://github.com/*)
            stacker_update_check_github_releases "$repository" "$current_version"
            ;;
        *)
            stacker_warn "Update checking not supported for repository type: $repository"
            return 1
            ;;
    esac
}

# Check GitHub releases
stacker_update_check_github_releases() {
    local repo_url="$1"
    local current_version="$2"
    
    # Extract owner/repo from URL
    local repo_path
    repo_path=$(echo "$repo_url" | sed 's|https://github.com/||' | sed 's|\.git$||')
    
    # Use GitHub API to get latest release
    local api_url="https://api.github.com/repos/$repo_path/releases/latest"
    local latest_release
    
    if command -v curl >/dev/null 2>&1; then
        latest_release=$(curl -s "$api_url" 2>/dev/null) || {
            stacker_warn "Failed to fetch release information"
            return 1
        }
    else
        stacker_warn "curl not available for update checking"
        return 1
    fi
    
    # Parse JSON to get tag name (simple parsing)
    local latest_version
    latest_version=$(echo "$latest_release" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    
    if [ -z "$latest_version" ]; then
        stacker_warn "Could not determine latest version"
        return 1
    fi
    
    stacker_log "Latest version: $latest_version"
    
    if [ "$current_version" = "$latest_version" ]; then
        stacker_log "✅ No updates available (already up to date)"
        return 0
    else
        stacker_log "📦 Update available: $current_version → $latest_version"
        return 1  # Updates available
    fi
}

# Perform update
stacker_update_perform() {
    local force="$1"
    
    stacker_log "Updating $STACKER_TECH_NAME..."
    
    # Check for updates first unless forced
    if [ "$force" != true ]; then
        if stacker_update_check; then
            stacker_log "No updates needed"
            return 0
        fi
    fi
    
    # Backup current state
    stacker_update_backup || {
        stacker_error "Failed to create backup"
        return 1
    }
    
    # Perform update based on repository type
    if [ -d ".git" ]; then
        stacker_update_git
    elif [ -f "stacker.yaml" ]; then
        stacker_update_manifest
    else
        stacker_error "Cannot determine update method"
        return 1
    fi
}

# Git-based update
stacker_update_git() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null) || {
        stacker_error "Failed to get current branch"
        return 1
    }
    
    stacker_log "Pulling latest changes from $current_branch..."
    
    # Pull changes
    git pull origin "$current_branch" || {
        stacker_error "Failed to pull changes"
        stacker_log "Use 'stacker rollback' to restore previous state"
        return 1
    }
    
    # Run post-update hooks if they exist
    if [ -f "post-update.sh" ]; then
        stacker_log "Running post-update script..."
        sh post-update.sh || stacker_warn "Post-update script failed"
    fi
    
    stacker_log "✅ Update completed successfully"
    return 0
}

# Manifest-based update
stacker_update_manifest() {
    stacker_warn "Manifest-based updates not available"
    stacker_log "Use git-based updates instead"
    return 1
}

# Create backup before update
stacker_update_backup() {
    local backup_dir backup_name
    backup_name="backup-$(date +%Y%m%d-%H%M%S)"
    backup_dir="${XDG_DATA_HOME:-$HOME/.local/share}/stacker/backups"
    
    mkdir -p "$backup_dir" || {
        stacker_error "Failed to create backup directory"
        return 1
    }
    
    local full_backup_path="$backup_dir/$backup_name"
    
    stacker_log "Creating backup: $full_backup_path"
    
    # Create backup
    cp -r "." "$full_backup_path" 2>/dev/null || {
        stacker_error "Failed to create backup"
        return 1
    }
    
    # Store backup info
    echo "$full_backup_path" > "${XDG_DATA_HOME:-$HOME/.local/share}/stacker/.last-backup"
    
    stacker_log "✓ Backup created successfully"
    return 0
}


# Rollback command - CLI interface
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
    
    local version=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --version=*)
                version="${1#--version=}"
                shift
                ;;
            *)
                # Treat as version if no prefix
                version="$1"
                shift
                ;;
        esac
    done
    
    stacker_log "Rolling back..."
    
    if [ -n "$version" ]; then
        stacker_rollback_to_version "$version"
    else
        stacker_rollback_to_previous
    fi
}

# Rollback to specific version
stacker_rollback_to_version() {
    local version="$1"
    
    stacker_log "Rolling back to version: $version"
    
    if [ -d ".git" ]; then
        # Git-based rollback
        git checkout "$version" || {
            stacker_error "Failed to checkout version: $version"
            return 1
        }
        stacker_log "✅ Rolled back to version: $version"
    else
        stacker_error "Version rollback only supported for git repositories"
        return 1
    fi
}

# Rollback to previous backup
stacker_rollback_to_previous() {
    local last_backup_file="${XDG_DATA_HOME:-$HOME/.local/share}/stacker/.last-backup"
    
    if [ ! -f "$last_backup_file" ]; then
        stacker_error "No backup found to rollback to"
        return 1
    fi
    
    local backup_path
    backup_path=$(cat "$last_backup_file") || {
        stacker_error "Failed to read backup information"
        return 1
    }
    
    if [ ! -d "$backup_path" ]; then
        stacker_error "Backup directory not found: $backup_path"
        return 1
    fi
    
    stacker_log "Rolling back to previous backup: $(basename "$backup_path")"
    
    # Confirm rollback
    printf "This will replace current files with backup. Continue? (yes/no): "
    read confirmation
    case "$confirmation" in
        yes|YES|y|Y) ;;
        *) 
            stacker_log "Rollback cancelled"
            return 1
            ;;
    esac
    
    # Create temp backup of current state
    local temp_backup
    temp_backup=$(stacker_create_temp_file "current-state") || {
        stacker_error "Failed to create temporary backup"
        return 1
    }
    
    cp -r "." "$temp_backup.dir" || {
        stacker_error "Failed to backup current state"
        return 1
    }
    
    # Remove current files (except .git)
    find . -maxdepth 1 -not -name '.' -not -name '..' -not -name '.git' -exec rm -rf {} + 2>/dev/null || true
    
    # Restore from backup
    cp -r "$backup_path"/* . || {
        stacker_error "Failed to restore from backup"
        stacker_log "Current state saved in: $temp_backup.dir"
        return 1
    }
    
    # Clean up temp backup
    rm -rf "$temp_backup.dir" 2>/dev/null || true
    
    stacker_log "✅ Rollback completed successfully"
    return 0
}

# Self-update command - updates Stacker framework itself
stacker_cli_self_update() {
    local check_only=false
    local channel="stable"
    
    # Parse common arguments first
    stacker_parse_common_args "self-update" "$@" || return $?
    
    # Parse command-specific arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --check)
                check_only=true
                shift
                ;;
            --channel=*)
                channel="${1#--channel=}"
                shift
                ;;
            --)
                shift
                break
                ;;
            --*|-*)
                stacker_unknown_option_error "self-update" "$1"
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Validate channel
    case "$channel" in
        stable|beta) ;;
        *)
            stacker_error "Invalid channel: $channel (use: stable, beta)"
            return 1
            ;;
    esac
    
    stacker_log "Checking for Stacker framework updates..."
    stacker_log "Channel: $channel"
    
    # Use GitHub API to check for latest release
    local repo="akaoio/stacker"
    local api_url
    
    if [ "$channel" = "stable" ]; then
        api_url="https://api.github.com/repos/$repo/releases/latest"
    else
        api_url="https://api.github.com/repos/$repo/releases"
    fi
    
    local release_info
    if command -v curl >/dev/null 2>&1; then
        release_info=$(curl -s "$api_url" 2>/dev/null) || {
            stacker_warn "Failed to fetch release information"
            return 1
        }
    else
        stacker_warn "curl not available for self-update"
        return 1
    fi
    
    # Parse latest version
    local latest_version
    if [ "$channel" = "stable" ]; then
        latest_version=$(echo "$release_info" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    else
        # For beta, get the first prerelease
        latest_version=$(echo "$release_info" | grep -A 1 '"prerelease": true' | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    fi
    
    if [ -z "$latest_version" ]; then
        stacker_warn "Could not determine latest version"
        return 1
    fi
    
    stacker_log "Current version: $STACKER_VERSION"
    stacker_log "Latest version: $latest_version"
    
    if [ "$STACKER_VERSION" = "$latest_version" ]; then
        stacker_log "✅ Stacker framework is up to date"
        return 0
    fi
    
    if [ "$check_only" = true ]; then
        stacker_log "📦 Framework update available: $STACKER_VERSION → $latest_version"
        return 1
    fi
    
    stacker_log "🔄 Updating Stacker framework..."
    stacker_warn "Self-update implementation coming soon"
    stacker_log "For now, manually update from: https://github.com/akaoio/stacker"
    
    return 1
}

# Module initialization
update_init() {
    stacker_debug "Update module initialized"
    return 0
}