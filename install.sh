#!/bin/sh
# Stacker Bootstrap Installer
# Install Stacker framework using XDG Base Directory Specification
# Version: 0.0.1

set -e

# Use standardized logging from core module if available
if command -v stacker_log >/dev/null 2>&1; then
    log() { stacker_log "$*"; }
    warn() { stacker_warn "$*"; }
    error() { stacker_error "$*"; }
    debug() { stacker_debug "$*"; }
else
    # Fallback colors for standalone usage
    if [ "${NO_COLOR:-0}" = "1" ] || [ "${FORCE_COLOR:-0}" = "0" ]; then
        RED='' GREEN='' YELLOW='' BLUE='' NC=''
    elif [ "${FORCE_COLOR:-0}" = "1" ] || { [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; }; then
        RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' NC=''
    fi
    
    # Fallback logging functions
    log() { printf "${GREEN}[INFO]${NC} %s\n" "$*"; }
    warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
    error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
    debug() { [ "$STACKER_DEBUG" = "true" ] && printf "${BLUE}[DEBUG]${NC} %s\n" "$*"; }
fi

# Configuration
# Read version from single source of truth
if [ -f "$SCRIPT_DIR/VERSION" ]; then
    STACKER_VERSION=$(cat "$SCRIPT_DIR/VERSION")
else
    STACKER_VERSION="0.0.1"  # Fallback
fi

# XDG Base Directory Compliance
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# XDG-compliant installation directories
INSTALL_DIR="$XDG_DATA_HOME/stacker"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$XDG_CONFIG_HOME/stacker"
STACKER_BIN="$BIN_DIR/stacker"

# Check if running from git repo
SCRIPT_DIR="$(dirname "$0")"
if [ ! -f "$SCRIPT_DIR/stacker.sh" ]; then
    error "install.sh must be run from Stacker source directory"
    exit 1
fi

# Main installation function
install_stacker() {
    log "Installing Stacker v$STACKER_VERSION to $INSTALL_DIR"
    
    # Create installation directory
    if [ -d "$INSTALL_DIR" ]; then
        warn "Stacker already installed at $INSTALL_DIR"
        read -p "Overwrite existing installation? (y/N): " confirm
        case "$confirm" in
            [yY]|[yY][eE][sS]) 
                log "Removing existing installation..."
                rm -rf "$INSTALL_DIR"
                ;;
            *)
                log "Installation cancelled"
                exit 0
                ;;
        esac
    fi
    
    # Create XDG-compliant directory structure
    log "Creating XDG-compliant directory structure..."
    mkdir -p "$BIN_DIR"
    mkdir -p "$INSTALL_DIR/src/sh"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$INSTALL_DIR/templates"
    
    # Copy core files - maintain same structure as development
    log "Copying Stacker framework files..."
    cp "$SCRIPT_DIR/stacker.sh" "$STACKER_BIN"
    cp "$SCRIPT_DIR/VERSION" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/src/sh/loader.sh" "$INSTALL_DIR/src/sh/"
    
    # Copy modules - maintain same structure as development
    if [ -d "$SCRIPT_DIR/src/sh/module" ]; then
        cp -r "$SCRIPT_DIR/src/sh/module" "$INSTALL_DIR/src/sh/"
    fi
    
    # Copy templates if they exist
    if [ -d "$SCRIPT_DIR/templates" ]; then
        cp -r "$SCRIPT_DIR/templates/"* "$INSTALL_DIR/templates/"
    fi
    
    # Make stacker executable
    chmod +x "$STACKER_BIN"
    
    # Update stacker.sh to use installed location (no path changes needed!)
    sed -i.bak "s|STACKER_DIR=.*|STACKER_DIR=\"$INSTALL_DIR\"|g" "$STACKER_BIN"
    rm -f "$STACKER_BIN.bak"
    
    log "Stacker framework installed successfully!"
}

# Add to PATH
setup_path() {
    log "Setting up PATH configuration..."
    
    # Determine shell profile
    SHELL_PROFILE=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.profile" ]; then
        SHELL_PROFILE="$HOME/.profile"
    else
        SHELL_PROFILE="$HOME/.profile"
        touch "$SHELL_PROFILE"
    fi
    
    # Check if already in PATH
    if echo "$PATH" | grep -q "$BIN_DIR"; then
        log "Stacker bin directory already in PATH"
    else
        log "Adding $BIN_DIR to PATH in $SHELL_PROFILE"
        echo "" >> "$SHELL_PROFILE"
        echo "# Stacker framework" >> "$SHELL_PROFILE"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_PROFILE"
        
        # Also export for current session
        export PATH="$BIN_DIR:$PATH"
    fi
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    if [ ! -f "$STACKER_BIN" ]; then
        error "Stacker binary not found at $STACKER_BIN"
        return 1
    fi
    
    if ! "$STACKER_BIN" version >/dev/null 2>&1; then
        error "Stacker binary not working properly"
        return 1
    fi
    
    local installed_version
    installed_version=$("$STACKER_BIN" version 2>/dev/null | head -1)
    log "Installed version: $installed_version"
    
    # Test basic functionality
    if "$STACKER_BIN" help >/dev/null 2>&1; then
        log "✅ Installation verified successfully!"
    else
        warn "Installation completed but some features may not work"
    fi
}

# Main installation flow
main() {
    log "🚀 Stacker Bootstrap Installer v$STACKER_VERSION"
    log "Target: $INSTALL_DIR"
    echo ""
    
    install_stacker
    setup_path
    verify_installation
    
    echo ""
    log "🎉 Stacker installation complete!"
    log ""
    log "Next steps:"
    log "1. Reload your shell: source ~/.profile (or restart terminal)"
    log "2. Test installation: stacker version"
    log "3. Install packages: stacker install access"
    log "4. Get help: stacker help"
    log ""
    log "XDG-Compliant Installation Locations:"
    log "  Framework: $INSTALL_DIR"
    log "  Binary: $STACKER_BIN"
    log "  Config: $CONFIG_DIR"
    log ""
    log "Happy stacking! 🥞"
}

# Run main function
main "$@"