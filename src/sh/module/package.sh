#!/bin/sh
# Stacker Package Management Module
# Universal POSIX Package Manager with XDG compliance

# Package management functions
STACKER_MODULE_NAME="package"
STACKER_MODULE_VERSION="1.0.0"

# XDG-compliant directories
stacker_get_package_dirs() {
    local scope="${1:-user}"
    
    case "$scope" in
        local)
            echo "$(pwd)/.stacker"
            ;;
        user)
            echo "${XDG_DATA_HOME:-$HOME/.local/share}/stacker/packages"
            ;;
        system)
            echo "/usr/local/share/stacker/packages"
            ;;
        *)
            stacker_error "Invalid scope: $scope (use: local, user, system)"
            return 1
            ;;
    esac
}

# Parse package URL
stacker_parse_package_url() {
    local url="$1"
    local name=""
    local source=""
    local ref="main"
    
    case "$url" in
        gh:*)
            # GitHub: gh:user/repo[@ref]
            source="https://github.com/${url#gh:}"
            name="$(echo "${url#gh:}" | cut -d'@' -f1 | cut -d'/' -f2)"
            if echo "$url" | grep -q '@'; then
                ref="$(echo "$url" | cut -d'@' -f2)"
                source="$(echo "$source" | cut -d'@' -f1)"
            fi
            source="$source.git"
            ;;
        gl:*)
            # GitLab: gl:user/repo[@ref]
            source="https://gitlab.com/${url#gl:}"
            name="$(echo "${url#gl:}" | cut -d'@' -f1 | cut -d'/' -f2)"
            if echo "$url" | grep -q '@'; then
                ref="$(echo "$url" | cut -d'@' -f2)"
                source="$(echo "$source" | cut -d'@' -f1)"
            fi
            source="$source.git"
            ;;
        https://*)
            # Direct URL
            source="$url"
            name="$(basename "$url" .git)"
            ;;
        file://*)
            # Local path
            source="${url#file://}"
            name="$(basename "$source")"
            ;;
        *)
            stacker_error "Unsupported package URL: $url"
            stacker_log "Supported formats:"
            stacker_log "  gh:user/repo[@ref]     - GitHub"
            stacker_log "  gl:user/repo[@ref]     - GitLab"
            stacker_log "  https://example.git    - Direct Git URL"
            stacker_log "  file:///local/path     - Local path"
            return 1
            ;;
    esac
    
    export STACKER_PKG_NAME="$name"
    export STACKER_PKG_SOURCE="$source"
    export STACKER_PKG_REF="$ref"
}

# Check if package is installed
stacker_package_installed() {
    local name="$1"
    local scope="${2:-user}"
    local pkg_dir="$(stacker_get_package_dirs "$scope")/$name"
    
    [ -d "$pkg_dir" ] && [ -f "$pkg_dir/stacker.yaml" ]
}

# Install package
stacker_install_package() {
    local url="$1"
    local scope="${2:-user}"
    
    # Parse package URL
    if ! stacker_parse_package_url "$url"; then
        return 1
    fi
    
    local name="$STACKER_PKG_NAME"
    local source="$STACKER_PKG_SOURCE"
    local ref="$STACKER_PKG_REF"
    
    # Get package directory
    local pkg_dir="$(stacker_get_package_dirs "$scope")"
    local install_dir="$pkg_dir/$name"
    
    stacker_log "Installing package: $name"
    stacker_log "  Source: $source"
    stacker_log "  Ref: $ref"
    stacker_log "  Scope: $scope"
    stacker_log "  Target: $install_dir"
    
    # Create package directory
    if [ "$scope" = "system" ] && [ ! -w "$(dirname "$pkg_dir")" ]; then
        sudo mkdir -p "$pkg_dir" || {
            stacker_error "Failed to create system package directory: $pkg_dir"
            return 1
        }
    else
        mkdir -p "$pkg_dir" || {
            stacker_error "Failed to create package directory: $pkg_dir"
            return 1
        }
    fi
    
    # Check if already installed
    if stacker_package_installed "$name" "$scope"; then
        stacker_warn "Package '$name' already installed in $scope scope"
        stacker_log "Use 'stacker update $name --$scope' to update"
        return 1
    fi
    
    # Clone/copy the package
    if echo "$source" | grep -q '\.git$'; then
        # Git repository
        stacker_log "Cloning Git repository..."
        if [ "$scope" = "system" ] && [ ! -w "$pkg_dir" ]; then
            sudo git clone --depth 1 --branch "$ref" "$source" "$install_dir" || {
                stacker_error "Failed to clone package repository"
                return 1
            }
        else
            git clone --depth 1 --branch "$ref" "$source" "$install_dir" || {
                stacker_error "Failed to clone package repository"
                return 1
            }
        fi
    elif [ -d "$source" ]; then
        # Local directory
        stacker_log "Copying local directory..."
        if [ "$scope" = "system" ] && [ ! -w "$pkg_dir" ]; then
            sudo cp -r "$source" "$install_dir" || {
                stacker_error "Failed to copy local package"
                return 1
            }
        else
            cp -r "$source" "$install_dir" || {
                stacker_error "Failed to copy local package"
                return 1
            }
        fi
    else
        stacker_error "Unsupported package source: $source"
        return 1
    fi
    
    # Check for package manifest
    if [ ! -f "$install_dir/stacker.yaml" ]; then
        stacker_warn "Package does not have stacker.yaml manifest"
        # Create basic manifest
        cat > "$install_dir/stacker.yaml" << EOF
name: "$name"
version: "unknown"
description: "Package installed from $url"
author: "unknown"
license: "unknown"
source: "$url"
EOF
        [ "$scope" = "system" ] && [ ! -w "$install_dir" ] && sudo chown root:root "$install_dir/stacker.yaml"
    fi
    
    # Run installation script if present
    if [ -f "$install_dir/install.sh" ]; then
        stacker_log "Running package installation script..."
        cd "$install_dir"
        if [ "$scope" = "system" ]; then
            sudo sh ./install.sh || {
                stacker_error "Package installation script failed"
                return 1
            }
        else
            sh ./install.sh || {
                stacker_error "Package installation script failed"
                return 1
            }
        fi
        cd - >/dev/null
    fi
    
    # Enable package by default
    stacker_enable_package "$name" "$scope"
    
    stacker_log "✓ Package '$name' installed successfully in $scope scope"
    return 0
}

# Remove package
stacker_remove_package() {
    local name="$1"
    local scope="${2:-user}"
    
    if ! stacker_package_installed "$name" "$scope"; then
        stacker_error "Package '$name' not installed in $scope scope"
        return 1
    fi
    
    local pkg_dir="$(stacker_get_package_dirs "$scope")/$name"
    
    stacker_log "Removing package: $name from $scope scope"
    
    # Run uninstallation script if present
    if [ -f "$pkg_dir/uninstall.sh" ]; then
        stacker_log "Running package uninstallation script..."
        cd "$pkg_dir"
        if [ "$scope" = "system" ]; then
            sudo sh ./uninstall.sh
        else
            sh ./uninstall.sh
        fi
        cd - >/dev/null
    fi
    
    # Disable package first
    stacker_disable_package "$name" "$scope" 2>/dev/null || true
    
    # Remove package directory
    if [ "$scope" = "system" ] && [ ! -w "$(dirname "$pkg_dir")" ]; then
        sudo rm -rf "$pkg_dir" || {
            stacker_error "Failed to remove system package directory"
            return 1
        }
    else
        rm -rf "$pkg_dir" || {
            stacker_error "Failed to remove package directory"
            return 1
        }
    fi
    
    stacker_log "✓ Package '$name' removed successfully from $scope scope"
    return 0
}

# List packages
stacker_list_packages() {
    local scope="${1:-user}"
    local pkg_dir="$(stacker_get_package_dirs "$scope")"
    
    if [ ! -d "$pkg_dir" ]; then
        echo "No packages installed in $scope scope"
        return 0
    fi
    
    echo "Packages installed in $scope scope:"
    
    for package in "$pkg_dir"/*; do
        if [ -d "$package" ] && [ -f "$package/stacker.yaml" ]; then
            local name="$(basename "$package")"
            local enabled="✗"
            
            # Check if enabled
            if stacker_package_enabled "$name" "$scope"; then
                enabled="✓"
            fi
            
            # Get version from manifest
            local version="unknown"
            if command -v grep >/dev/null 2>&1; then
                version="$(grep '^version:' "$package/stacker.yaml" 2>/dev/null | cut -d'"' -f2 | head -1)"
                [ -z "$version" ] && version="unknown"
            fi
            
            printf "  %-20s %-10s %s\n" "$name" "$version" "$enabled"
        fi
    done
}

# Enable package
stacker_enable_package() {
    local name="$1"
    local scope="${2:-user}"
    
    if ! stacker_package_installed "$name" "$scope"; then
        stacker_error "Package '$name' not installed in $scope scope"
        return 1
    fi
    
    local pkg_dir="$(stacker_get_package_dirs "$scope")/$name"
    local enable_dir=""
    
    case "$scope" in
        local)
            enable_dir="$(pwd)/.stacker/enabled"
            ;;
        user)
            enable_dir="${XDG_CONFIG_HOME:-$HOME/.config}/stacker/enabled"
            ;;
        system)
            enable_dir="/etc/stacker/enabled"
            ;;
    esac
    
    # Create enabled directory
    if [ "$scope" = "system" ] && [ ! -w "$(dirname "$enable_dir")" ]; then
        sudo mkdir -p "$enable_dir"
    else
        mkdir -p "$enable_dir"
    fi
    
    # Create symlink to enable
    local link_target="$enable_dir/$name"
    if [ "$scope" = "system" ] && [ ! -w "$enable_dir" ]; then
        sudo ln -sf "$pkg_dir" "$link_target" || {
            stacker_error "Failed to enable system package"
            return 1
        }
    else
        ln -sf "$pkg_dir" "$link_target" || {
            stacker_error "Failed to enable package"
            return 1
        }
    fi
    
    # Run enable script if present
    if [ -f "$pkg_dir/enable.sh" ]; then
        cd "$pkg_dir"
        if [ "$scope" = "system" ]; then
            sudo sh ./enable.sh
        else
            sh ./enable.sh
        fi
        cd - >/dev/null
    fi
    
    stacker_log "✓ Package '$name' enabled in $scope scope"
    return 0
}

# Disable package
stacker_disable_package() {
    local name="$1"
    local scope="${2:-user}"
    
    local enable_dir=""
    
    case "$scope" in
        local)
            enable_dir="$(pwd)/.stacker/enabled"
            ;;
        user)
            enable_dir="${XDG_CONFIG_HOME:-$HOME/.config}/stacker/enabled"
            ;;
        system)
            enable_dir="/etc/stacker/enabled"
            ;;
    esac
    
    local link_target="$enable_dir/$name"
    
    if [ ! -L "$link_target" ]; then
        stacker_error "Package '$name' not enabled in $scope scope"
        return 1
    fi
    
    # Run disable script if present
    local pkg_dir="$(readlink "$link_target")"
    if [ -f "$pkg_dir/disable.sh" ]; then
        cd "$pkg_dir"
        if [ "$scope" = "system" ]; then
            sudo sh ./disable.sh
        else
            sh ./disable.sh
        fi
        cd - >/dev/null
    fi
    
    # Remove symlink
    if [ "$scope" = "system" ] && [ ! -w "$enable_dir" ]; then
        sudo rm -f "$link_target"
    else
        rm -f "$link_target"
    fi
    
    stacker_log "✓ Package '$name' disabled in $scope scope"
    return 0
}

# Check if package is enabled
stacker_package_enabled() {
    local name="$1"
    local scope="${2:-user}"
    
    local enable_dir=""
    
    case "$scope" in
        local)
            enable_dir="$(pwd)/.stacker/enabled"
            ;;
        user)
            enable_dir="${XDG_CONFIG_HOME:-$HOME/.config}/stacker/enabled"
            ;;
        system)
            enable_dir="/etc/stacker/enabled"
            ;;
    esac
    
    [ -L "$enable_dir/$name" ]
}

# Get package info
stacker_package_info() {
    local name="$1"
    local scope="${2:-user}"
    
    if ! stacker_package_installed "$name" "$scope"; then
        stacker_error "Package '$name' not installed in $scope scope"
        return 1
    fi
    
    local pkg_dir="$(stacker_get_package_dirs "$scope")/$name"
    local manifest="$pkg_dir/stacker.yaml"
    
    echo "Package Information: $name"
    echo "Scope: $scope"
    echo "Location: $pkg_dir"
    echo "Enabled: $(stacker_package_enabled "$name" "$scope" && echo "Yes" || echo "No")"
    echo ""
    
    if [ -f "$manifest" ]; then
        echo "Manifest (stacker.yaml):"
        echo "----------------------"
        cat "$manifest" 2>/dev/null || echo "Error reading manifest"
    else
        echo "No manifest file found"
    fi
}

# Search for packages
stacker_search_packages() {
    local query="$1"
    
    if [ -z "$query" ]; then
        stacker_error "Search query required"
        return 1
    fi
    
    echo "Package Search: '$query'"
    
    # Search in GitHub via API
    local github_results
    github_results=$(curl -s "https://api.github.com/search/repositories?q=${query}+topic:stacker+topic:shell" | \
        grep -E '"full_name"|"description"' | \
        sed 'N;s/\n/ /' | \
        head -10 | \
        sed 's/.*"full_name": "\([^"]*\)".* "description": "\([^"]*\)".*/  gh:\1 - \2/')
    
    if [ -n "$github_results" ]; then
        echo "GitHub repositories:"
        echo "$github_results"
    else
        # Fallback to common AKAO repositories
        echo "Common AKAO packages:"
        echo "  gh:akaoio/air - Distributed P2P Database"
        echo "  gh:akaoio/access - Network Access Layer"
        echo "  gh:akaoio/composer - Documentation Engine"
        echo "  gh:akaoio/battle - Terminal Testing Framework"
        echo "  gh:akaoio/builder - TypeScript Build Framework"
    fi
    
    echo ""
    echo "Usage: stacker install <package-url>"
    echo ""
    echo "You can install packages directly:"
    echo "  stacker install gh:user/repo"
    echo "  stacker install gl:user/repo"
    echo "  stacker install https://example.com/repo.git"
}

# Module initialization
package_init() {
    stacker_debug "Package management module initialized"
    return 0
}