#!/bin/sh
# Module: install
# Description: Installation workflow functions for various application types
# Dependencies: core config
# Provides: clean cloning, multi-language installation, verification

# Module metadata
MANAGER_MODULE_NAME="install"
MANAGER_MODULE_VERSION="1.0.0"
MANAGER_MODULE_DEPENDENCIES="core config"
MANAGER_MODULE_LOADED=false

# Module initialization
install_init() {
    MANAGER_MODULE_LOADED=true
    manager_debug "Install module initialized"
    return 0
}

# Create clean clone of repository using the Access philosophy
manager_create_clean_clone() {
    local repo_url="$MANAGER_REPO_URL"
    local clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    local current_dir
    
    if [ -z "$repo_url" ] || [ -z "$clone_dir" ]; then
        manager_error "Repository URL and clone directory must be set"
        return 1
    fi
    
    manager_log "Creating clean clone at $clone_dir..."
    current_dir=$(pwd)
    
    # SMART UPDATE: If running from target directory, update in place
    if [ "$current_dir" = "$clone_dir" ]; then
        manager_log "Running from target directory - updating in place..."
        
        if [ -d ".git" ]; then
            manager_log "Updating existing repository..."
            git fetch origin >/dev/null 2>&1 || {
                manager_warn "Failed to fetch updates from $repo_url"
                return 1
            }
            
            # Check if update needed
            local local_hash remote_hash
            local_hash=$(git rev-parse HEAD 2>/dev/null)
            remote_hash=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
            
            if [ "$local_hash" != "$remote_hash" ]; then
                manager_log "Updates available, pulling changes..."
                git reset --hard "$remote_hash" >/dev/null 2>&1 || {
                    manager_error "Failed to reset to latest version"
                    return 1
                }
                manager_log "Repository updated successfully"
            else
                manager_log "Repository already up to date"
            fi
        else
            manager_error "Current directory is not a git repository"
            return 1
        fi
        
        return 0
    fi
    
    # Normal clean clone for external installation
    if [ -d "$clone_dir" ]; then
        manager_log "Removing existing clone..."
        rm -rf "$clone_dir" || {
            manager_error "Failed to remove existing clone"
            return 1
        }
    fi
    
    # Clone fresh repository
    manager_log "Cloning from $repo_url..."
    git clone "$repo_url" "$clone_dir" >/dev/null 2>&1 || {
        manager_error "Failed to clone repository from $repo_url"
        return 1
    }
    
    # Verify main script exists
    if [ -n "$MANAGER_MAIN_SCRIPT" ] && [ ! -f "$clone_dir/$MANAGER_MAIN_SCRIPT" ]; then
        manager_error "Main script not found: $clone_dir/$MANAGER_MAIN_SCRIPT"
        return 1
    fi
    
    manager_log "Clean clone created successfully"
    return 0
}

# Install from clean clone
manager_install_from_clone() {
    local clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    local install_dir="$MANAGER_INSTALL_DIR"
    local tech_name="$MANAGER_TECH_NAME"
    local main_script="$MANAGER_MAIN_SCRIPT"
    local source_file="$clone_dir/$main_script"
    local dest_file="$install_dir/$tech_name"
    
    if [ ! -d "$clone_dir" ]; then
        manager_error "Clean clone directory not found: $clone_dir"
        return 1
    fi
    
    manager_log "Installing $tech_name from clean clone..."
    
    # Ensure installation directory exists
    if [ ! -d "$install_dir" ]; then
        manager_log "Creating installation directory: $install_dir"
        manager_exec_privileged "$install_dir" mkdir -p "$install_dir" || return 1
    fi
    
    # Handle different installation types
    if [ -f "$source_file" ]; then
        # Direct script installation
        manager_install_script "$source_file" "$dest_file"
    elif [ -f "$clone_dir/package.json" ]; then
        # Node.js application
        manager_install_nodejs_app "$clone_dir" "$dest_file"
    elif [ -f "$clone_dir/Cargo.toml" ]; then
        # Rust application  
        manager_install_rust_app "$clone_dir" "$dest_file"
    elif [ -f "$clone_dir/go.mod" ]; then
        # Go application
        manager_install_go_app "$clone_dir" "$dest_file"
    else
        manager_error "Unknown application type in $clone_dir"
        return 1
    fi
}

# Install shell script
manager_install_script() {
    local source_file="$1"
    local dest_file="$2"
    
    manager_debug "Installing script: $source_file -> $dest_file"
    
    # Copy main script
    manager_exec_privileged "$MANAGER_INSTALL_DIR" cp "$source_file" "$dest_file" || return 1
    manager_exec_privileged "$MANAGER_INSTALL_DIR" chmod +x "$dest_file" || return 1
    
    # Install additional files based on project configuration
    local clone_dir="$MANAGER_CLEAN_CLONE_DIR"
    local config_file="$clone_dir/.manager-config"
    
    # Read project-specific configuration if it exists
    if [ -f "$config_file" ]; then
        # Source the config to get ADDITIONAL_FILES and LEGACY_FILES
        . "$config_file"
        
        # Remove legacy files if specified
        if [ -n "$LEGACY_FILES" ]; then
            for legacy_file in $LEGACY_FILES; do
                if [ -f "$MANAGER_INSTALL_DIR/$legacy_file" ]; then
                    manager_exec_privileged "$MANAGER_INSTALL_DIR" rm -f "$MANAGER_INSTALL_DIR/$legacy_file"
                    manager_debug "Removed legacy file: $legacy_file"
                fi
            done
        fi
        
        # Install additional files if specified
        if [ -n "$ADDITIONAL_FILES" ]; then
            for file in $ADDITIONAL_FILES; do
                if [ -f "$clone_dir/$file" ]; then
                    dest="$MANAGER_INSTALL_DIR/$file"
                    manager_exec_privileged "$MANAGER_INSTALL_DIR" cp "$clone_dir/$file" "$dest"
                    manager_exec_privileged "$MANAGER_INSTALL_DIR" chmod +x "$dest"
                    manager_debug "Installed additional file: $file"
                fi
            done
        fi
    fi
    
    # Install directories if specified in configuration
    if [ -n "$DIRECTORIES" ]; then
        for dir in $DIRECTORIES; do
            if [ -d "$clone_dir/$dir" ]; then
                local dir_dest="$MANAGER_INSTALL_DIR/$dir"
                manager_exec_privileged "$MANAGER_INSTALL_DIR" cp -r "$clone_dir/$dir" "$dir_dest"
                manager_exec_privileged "$MANAGER_INSTALL_DIR" chmod -R +x "$dir_dest"/*.sh 2>/dev/null || true
                manager_debug "Installed directory: $dir"
            fi
        done
    fi
    
    manager_log "Script installation completed"
    return 0
}

# Install Node.js application
manager_install_nodejs_app() {
    local clone_dir="$1"
    local dest_file="$2"
    local wrapper_script
    
    manager_debug "Installing Node.js application from $clone_dir"
    
    # Check Node.js requirements
    if ! command -v node >/dev/null 2>&1; then
        manager_error "Node.js is required but not found"
        return 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        manager_error "npm is required but not found"
        return 1
    fi
    
    # Install npm dependencies in clean clone
    manager_log "Installing npm dependencies..."
    cd "$clone_dir" || return 1
    npm install --production >/dev/null 2>&1 || {
        manager_error "Failed to install npm dependencies"
        return 1
    }
    
    # Determine Node.js entry point
    local entry_point="main.js"
    if [ -n "$NODE_ENTRY_POINT" ]; then
        entry_point="$NODE_ENTRY_POINT"
    elif [ -f "$clone_dir/package.json" ] && command -v node >/dev/null 2>&1; then
        # Try to extract main from package.json
        local pkg_main
        pkg_main=$(node -p "try { require('./package.json').main } catch(e) { 'main.js' }" 2>/dev/null)
        [ -n "$pkg_main" ] && [ "$pkg_main" != "undefined" ] && entry_point="$pkg_main"
    fi

    # Create wrapper script
    wrapper_script=$(manager_create_temp_file "nodejs-wrapper") || return 1
    
    cat > "$wrapper_script" << EOF
#!/bin/sh
# $MANAGER_TECH_NAME wrapper script - launches from clean clone with XDG paths

CLEAN_CLONE_DIR="$clone_dir"
XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-\$HOME/.config}"
XDG_DATA_HOME="\${XDG_DATA_HOME:-\$HOME/.local/share}"
XDG_STATE_HOME="\${XDG_STATE_HOME:-\$HOME/.local/state}"

export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME

# Ensure clean clone exists
if [ ! -d "\$CLEAN_CLONE_DIR" ]; then
    echo "Error: $MANAGER_TECH_NAME not properly installed (missing \$CLEAN_CLONE_DIR)"
    echo "Please run the installer again"
    exit 1
fi

# Run application from clean clone
cd "\$CLEAN_CLONE_DIR" || exit 1
exec node $entry_point "\$@"
EOF
    
    # Install wrapper script
    manager_exec_privileged "$MANAGER_INSTALL_DIR" cp "$wrapper_script" "$dest_file" || return 1
    manager_exec_privileged "$MANAGER_INSTALL_DIR" chmod +x "$dest_file" || return 1
    rm -f "$wrapper_script"
    
    manager_log "Node.js application installation completed"
    return 0
}

# Install Rust application
manager_install_rust_app() {
    local clone_dir="$1"
    local dest_file="$2"
    
    manager_debug "Installing Rust application from $clone_dir"
    
    if ! command -v cargo >/dev/null 2>&1; then
        manager_error "Cargo is required but not found"
        return 1
    fi
    
    # Build release binary
    manager_log "Building Rust application..."
    cd "$clone_dir" || return 1
    cargo build --release >/dev/null 2>&1 || {
        manager_error "Failed to build Rust application"
        return 1
    }
    
    # Find and install binary
    local binary_name="$MANAGER_TECH_NAME"
    local binary_path="$clone_dir/target/release/$binary_name"
    
    if [ ! -f "$binary_path" ]; then
        manager_error "Built binary not found: $binary_path"
        return 1
    fi
    
    manager_exec_privileged "$MANAGER_INSTALL_DIR" cp "$binary_path" "$dest_file" || return 1
    manager_exec_privileged "$MANAGER_INSTALL_DIR" chmod +x "$dest_file" || return 1
    
    manager_log "Rust application installation completed"
    return 0
}

# Install Go application  
manager_install_go_app() {
    local clone_dir="$1"
    local dest_file="$2"
    
    manager_debug "Installing Go application from $clone_dir"
    
    if ! command -v go >/dev/null 2>&1; then
        manager_error "Go is required but not found"
        return 1
    fi
    
    # Build binary
    manager_log "Building Go application..."
    cd "$clone_dir" || return 1
    go build -o "$MANAGER_TECH_NAME" . >/dev/null 2>&1 || {
        manager_error "Failed to build Go application"
        return 1
    }
    
    # Install binary
    manager_exec_privileged "$MANAGER_INSTALL_DIR" cp "$MANAGER_TECH_NAME" "$dest_file" || return 1
    manager_exec_privileged "$MANAGER_INSTALL_DIR" chmod +x "$dest_file" || return 1
    
    manager_log "Go application installation completed"
    return 0
}

# Verify installation
manager_verify_installation() {
    local dest_file="$MANAGER_INSTALL_DIR/$MANAGER_TECH_NAME"
    
    manager_debug "Verifying installation..."
    
    if [ ! -f "$dest_file" ]; then
        manager_error "Installation verification failed: $dest_file not found"
        return 1
    fi
    
    if [ ! -x "$dest_file" ]; then
        manager_error "Installation verification failed: $dest_file not executable"
        return 1
    fi
    
    # Test execution if possible
    if "$dest_file" --version >/dev/null 2>&1 || "$dest_file" version >/dev/null 2>&1; then
        manager_log "Installation verified successfully"
    else
        manager_warn "Installation completed but version check failed"
    fi
    
    return 0
}

# Export public interface
install_list_functions() {
    echo "manager_create_clean_clone manager_install_from_clone manager_verify_installation"
    echo "manager_install_script manager_install_nodejs_app manager_install_rust_app manager_install_go_app"
}