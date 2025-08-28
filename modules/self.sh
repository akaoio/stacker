#!/bin/sh
# Stacker Self-Management Module
# Self-installation and uninstallation functionality

# Module metadata
STACKER_MODULE_NAME="self"
STACKER_MODULE_VERSION="1.0.0"

# Self-install command - installs Stacker framework itself
stacker_cli_self_install() {
    local install_dir=""
    local use_sudo=false
    local force=false
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --dir=*)
                install_dir="${1#--dir=}"
                shift
                ;;
            --sudo)
                use_sudo=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                stacker_error "Unknown self-install option: $1"
                return 1
                ;;
        esac
    done
    
    # Determine installation directory
    if [ -z "$install_dir" ]; then
        if [ "$use_sudo" = true ] || [ -w "/usr/local/bin" ]; then
            install_dir="/usr/local/bin"
        else
            install_dir="$HOME/.local/bin"
            mkdir -p "$install_dir"
        fi
    fi
    
    stacker_log "Installing Stacker framework to: $install_dir"
    
    # Check if already installed
    local existing_stacker="$install_dir/stacker"
    if [ -f "$existing_stacker" ] && [ "$force" != true ]; then
        stacker_error "Stacker already installed at $existing_stacker"
        stacker_log "Use --force to overwrite"
        return 1
    fi
    
    # Create wrapper script
    local temp_wrapper
    temp_wrapper=$(stacker_create_temp_file "stacker-wrapper") || {
        stacker_error "Failed to create temporary wrapper script"
        return 1
    }
    
    cat > "$temp_wrapper" << 'EOF'
#!/bin/sh
# Stacker Framework Wrapper
# Auto-generated installer wrapper

# Find Stacker installation
STACKER_INSTALL_DIR=""

# Check common locations
for dir in \
    "$HOME/.local/share/stacker" \
    "/usr/local/share/stacker" \
    "/opt/stacker" \
    "$(dirname "$0")/../share/stacker" \
    "$(dirname "$0")/stacker"
do
    if [ -f "$dir/stacker.sh" ]; then
        STACKER_INSTALL_DIR="$dir"
        break
    fi
done

# Fallback to relative path
if [ -z "$STACKER_INSTALL_DIR" ]; then
    # Try relative to this script
    script_dir="$(dirname "$0")"
    if [ -f "$script_dir/stacker.sh" ]; then
        STACKER_INSTALL_DIR="$script_dir"
    fi
fi

if [ -z "$STACKER_INSTALL_DIR" ] || [ ! -f "$STACKER_INSTALL_DIR/stacker.sh" ]; then
    echo "Error: Stacker framework not found" >&2
    echo "Searched in:" >&2
    echo "  $HOME/.local/share/stacker" >&2
    echo "  /usr/local/share/stacker" >&2
    echo "  /opt/stacker" >&2
    echo "  $(dirname "$0")/../share/stacker" >&2
    echo "  $(dirname "$0")/stacker" >&2
    exit 1
fi

# Set environment and execute
export STACKER_DIR="$STACKER_INSTALL_DIR"
exec "$STACKER_INSTALL_DIR/stacker.sh" "$@"
EOF
    
    # Install wrapper script
    if [ "$use_sudo" = true ] && [ ! -w "$install_dir" ]; then
        sudo cp "$temp_wrapper" "$existing_stacker" || {
            stacker_error "Failed to install wrapper script"
            return 1
        }
        sudo chmod +x "$existing_stacker"
    else
        cp "$temp_wrapper" "$existing_stacker" || {
            stacker_error "Failed to install wrapper script"  
            return 1
        }
        chmod +x "$existing_stacker"
    fi
    
    # Copy framework files
    local framework_dir
    if [ "$use_sudo" = true ] || [ -w "/usr/local/share" ]; then
        framework_dir="/usr/local/share/stacker"
    else
        framework_dir="$HOME/.local/share/stacker"
    fi
    
    stacker_log "Installing framework files to: $framework_dir"
    
    # Create framework directory
    if [ "$use_sudo" = true ] && [ ! -w "$(dirname "$framework_dir")" ]; then
        sudo mkdir -p "$framework_dir"
    else
        mkdir -p "$framework_dir"
    fi
    
    # Copy all framework files
    local files_to_copy="stacker.sh stacker-loader.sh modules"
    for file in $files_to_copy; do
        if [ -e "$STACKER_DIR/$file" ]; then
            if [ "$use_sudo" = true ] && [ ! -w "$framework_dir" ]; then
                sudo cp -r "$STACKER_DIR/$file" "$framework_dir/"
            else
                cp -r "$STACKER_DIR/$file" "$framework_dir/"
            fi
        fi
    done
    
    # Add to PATH if needed
    case ":$PATH:" in
        *":$install_dir:"*) ;;
        *)
            stacker_warn "Add $install_dir to your PATH:"
            stacker_log "  echo 'export PATH=\"$install_dir:\$PATH\"' >> ~/.bashrc"
            stacker_log "  source ~/.bashrc"
            ;;
    esac
    
    stacker_log "✓ Stacker framework installed successfully"
    stacker_log "  Wrapper: $existing_stacker"
    stacker_log "  Framework: $framework_dir"
    stacker_log "  Test with: stacker version"
    
    return 0
}

# Self-uninstall command - removes Stacker framework
stacker_cli_self_uninstall() {
    local force=false
    local remove_data=false
    
    # Parse arguments  
    while [ $# -gt 0 ]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            --remove-data)
                remove_data=true
                shift
                ;;
            *)
                stacker_error "Unknown self-uninstall option: $1"
                return 1
                ;;
        esac
    done
    
    stacker_log "Uninstalling Stacker framework..."
    
    # Confirm unless force
    if [ "$force" != true ]; then
        printf "This will remove Stacker framework completely. Continue? (yes/no): "
        read confirmation
        case "$confirmation" in
            yes|YES|y|Y) ;;
            *) 
                stacker_log "Uninstall cancelled"
                return 1
                ;;
        esac
    fi
    
    # Find installation locations
    local locations_found=""
    local wrapper_found=""
    
    # Find wrapper scripts
    for dir in "/usr/local/bin" "$HOME/.local/bin" "/usr/bin"; do
        if [ -f "$dir/stacker" ]; then
            wrapper_found="$wrapper_found $dir/stacker"
            locations_found="yes"
        fi
    done
    
    # Find framework installations
    local framework_locations=""
    for dir in "/usr/local/share/stacker" "$HOME/.local/share/stacker" "/opt/stacker"; do
        if [ -d "$dir" ] && [ -f "$dir/stacker.sh" ]; then
            framework_locations="$framework_locations $dir"
            locations_found="yes"
        fi
    done
    
    if [ -z "$locations_found" ]; then
        stacker_warn "No Stacker installations found"
        return 1
    fi
    
    # Remove wrapper scripts
    for wrapper in $wrapper_found; do
        stacker_log "Removing wrapper: $wrapper"
        if [ -w "$(dirname "$wrapper")" ]; then
            rm -f "$wrapper"
        else
            sudo rm -f "$wrapper"
        fi
    done
    
    # Remove framework directories
    for framework_dir in $framework_locations; do
        stacker_log "Removing framework: $framework_dir"
        if [ -w "$(dirname "$framework_dir")" ]; then
            rm -rf "$framework_dir"
        else
            sudo rm -rf "$framework_dir"
        fi
    done
    
    # Remove user data if requested
    if [ "$remove_data" = true ]; then
        local data_locations="$HOME/.local/share/stacker $HOME/.config/stacker $HOME/.cache/stacker"
        for data_dir in $data_locations; do
            if [ -d "$data_dir" ]; then
                stacker_log "Removing user data: $data_dir"
                rm -rf "$data_dir"
            fi
        done
    fi
    
    stacker_log "✓ Stacker framework uninstalled successfully"
    [ "$remove_data" != true ] && stacker_log "User data preserved (use --remove-data to remove)"
    
    return 0
}

# Module initialization
self_init() {
    stacker_debug "Self-management module initialized"
    return 0
}