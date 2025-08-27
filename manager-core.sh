#!/bin/sh
# @akaoio/manager - Core utilities and logging functions
# PURE POSIX shell implementation - fully compliant

# XDG Base Directory Specification compliance
MANAGER_XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
MANAGER_XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" 
MANAGER_XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
MANAGER_XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Manager framework XDG directories
MANAGER_CONFIG_DIR="$MANAGER_XDG_CONFIG_HOME/manager"
MANAGER_DATA_DIR="$MANAGER_XDG_DATA_HOME/manager"
MANAGER_STATE_DIR="$MANAGER_XDG_STATE_HOME/manager"
MANAGER_CACHE_DIR="$MANAGER_XDG_CACHE_HOME/manager"

# Colors for output (POSIX compliant terminal detection)
if [ -t 1 ] && [ -t 2 ]; then
    # Only use colors if both stdout and stderr are terminals
    case "$TERM" in
        *color*|xterm*|screen*|tmux*)
            MANAGER_RED='\033[0;31m'
            MANAGER_GREEN='\033[0;32m' 
            MANAGER_YELLOW='\033[1;33m'
            MANAGER_BLUE='\033[0;34m'
            MANAGER_NC='\033[0m'
            ;;
        *)
            MANAGER_RED=''
            MANAGER_GREEN=''
            MANAGER_YELLOW=''
            MANAGER_BLUE=''
            MANAGER_NC=''
            ;;
    esac
else
    MANAGER_RED=''
    MANAGER_GREEN=''
    MANAGER_YELLOW=''
    MANAGER_BLUE=''
    MANAGER_NC=''
fi

# Logging functions with XDG-compliant log file
manager_get_log_file() {
    if [ -n "$MANAGER_TECH_NAME" ]; then
        echo "$MANAGER_XDG_DATA_HOME/$MANAGER_TECH_NAME/manager.log"
    else
        echo "$MANAGER_DATA_DIR/manager.log"
    fi
}

manager_log_to_file() {
    local log_file
    log_file=$(manager_get_log_file)
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
    
    # Log with timestamp (POSIX date format)
    printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$log_file" 2>/dev/null || true
}

manager_log() {
    printf "%s[Manager]%s %s\n" "$MANAGER_GREEN" "$MANAGER_NC" "$*"
    manager_log_to_file "LOG: $*"
}

manager_info() {
    printf "%s[Info]%s %s\n" "$MANAGER_BLUE" "$MANAGER_NC" "$*"
    manager_log_to_file "INFO: $*"
}

manager_warn() {
    printf "%s[Warning]%s %s\n" "$MANAGER_YELLOW" "$MANAGER_NC" "$*" >&2
    manager_log_to_file "WARN: $*"
}

manager_error() {
    printf "%s[Error]%s %s\n" "$MANAGER_RED" "$MANAGER_NC" "$*" >&2
    manager_log_to_file "ERROR: $*"
}

# Debug logging (controlled by MANAGER_DEBUG environment variable)
manager_debug() {
    if [ "$MANAGER_DEBUG" = "1" ] || [ "$MANAGER_DEBUG" = "true" ]; then
        printf "%s[Debug]%s %s\n" "$MANAGER_BLUE" "$MANAGER_NC" "$*" >&2
        manager_log_to_file "DEBUG: $*"
    fi
}

# POSIX-compliant case conversion functions
manager_to_upper() {
    printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'
}

manager_to_lower() {
    printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]'
}

# OS and package manager detection (POSIX compliant)
manager_detect_os() {
    if [ -r /etc/os-release ]; then
        # Source the file safely
        . /etc/os-release 2>/dev/null && printf '%s\n' "${ID:-unknown}"
    elif command -v uname >/dev/null 2>&1; then
        case "$(uname -s 2>/dev/null)" in
            Linux) printf 'linux\n' ;;
            Darwin) printf 'macos\n' ;;
            FreeBSD) printf 'freebsd\n' ;;
            OpenBSD) printf 'openbsd\n' ;;
            NetBSD) printf 'netbsd\n' ;;
            SunOS) printf 'solaris\n' ;;
            AIX) printf 'aix\n' ;;
            *) printf 'unknown\n' ;;
        esac
    else
        printf 'unknown\n'
    fi
}

manager_detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        printf 'apt\n'
    elif command -v yum >/dev/null 2>&1; then
        printf 'yum\n'
    elif command -v dnf >/dev/null 2>&1; then
        printf 'dnf\n'
    elif command -v apk >/dev/null 2>&1; then
        printf 'apk\n'
    elif command -v brew >/dev/null 2>&1; then
        printf 'brew\n'
    elif command -v pkg >/dev/null 2>&1; then
        printf 'pkg\n'
    elif command -v pacman >/dev/null 2>&1; then
        printf 'pacman\n'
    elif command -v zypper >/dev/null 2>&1; then
        printf 'zypper\n'
    else
        printf 'none\n'
    fi
}

# Auto-install missing dependencies (POSIX compliant)
manager_auto_install_deps() {
    local packages="$1"
    local pm
    
    if [ -z "$packages" ]; then
        return 0
    fi
    
    pm=$(manager_detect_package_manager)
    manager_debug "Detected package manager: $pm"
    
    case "$pm" in
        apt)
            manager_log "Installing packages with apt: $packages"
            if sudo -n true 2>/dev/null; then
                sudo apt-get update >/dev/null 2>&1 || return 1
                # Use word splitting intentionally for packages
                # shellcheck disable=SC2086
                sudo apt-get install -y $packages >/dev/null 2>&1 || return 1
            else
                manager_error "apt requires sudo privileges"
                return 1
            fi
            ;;
        yum)
            manager_log "Installing packages with yum: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo yum install -y $packages >/dev/null 2>&1 || return 1
            else
                manager_error "yum requires sudo privileges"
                return 1
            fi
            ;;
        dnf)
            manager_log "Installing packages with dnf: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo dnf install -y $packages >/dev/null 2>&1 || return 1
            else
                manager_error "dnf requires sudo privileges"
                return 1
            fi
            ;;
        apk)
            manager_log "Installing packages with apk: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo apk add --no-cache $packages >/dev/null 2>&1 || return 1
            else
                manager_error "apk requires sudo privileges"
                return 1
            fi
            ;;
        brew)
            manager_log "Installing packages with brew: $packages"
            # Homebrew typically doesn't need sudo
            # shellcheck disable=SC2086
            brew install $packages >/dev/null 2>&1 || return 1
            ;;
        pkg)
            manager_log "Installing packages with pkg: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo pkg install -y $packages >/dev/null 2>&1 || return 1
            else
                manager_error "pkg requires sudo privileges"
                return 1
            fi
            ;;
        pacman)
            manager_log "Installing packages with pacman: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo pacman -S --noconfirm $packages >/dev/null 2>&1 || return 1
            else
                manager_error "pacman requires sudo privileges"
                return 1
            fi
            ;;
        zypper)
            manager_log "Installing packages with zypper: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo zypper install -y $packages >/dev/null 2>&1 || return 1
            else
                manager_error "zypper requires sudo privileges"
                return 1
            fi
            ;;
        *)
            manager_error "No supported package manager found"
            return 1
            ;;
    esac
    
    manager_log "Successfully installed: $packages"
    return 0
}

# Check for required tools and auto-install if possible (POSIX compliant)
manager_check_requirements() {
    local missing=""
    local missing_packages=""
    local arg1 arg2
    
    manager_debug "Checking requirements..."
    
    # Process tool/package pairs from arguments
    while [ $# -ge 2 ]; do
        arg1="$1"
        arg2="$2"
        shift 2
        
        if ! command -v "$arg1" >/dev/null 2>&1; then
            missing="$missing $arg1"
            missing_packages="$missing_packages $arg2"
        fi
    done
    
    # Default requirements if none specified
    if [ $# -eq 0 ] && [ -z "$missing" ]; then
        # Check git
        if ! command -v git >/dev/null 2>&1; then
            missing="$missing git"
            missing_packages="$missing_packages git"
        fi
        
        # Check curl or wget
        if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
            missing="$missing curl/wget"
            missing_packages="$missing_packages curl"
        fi
    fi
    
    if [ -n "$missing" ]; then
        manager_warn "Missing required tools:$missing"
        
        # Try auto-install if we have sudo
        if sudo -n true 2>/dev/null || [ "$(id -u)" -eq 0 ]; then
            manager_log "Attempting to auto-install missing dependencies..."
            if manager_auto_install_deps "$missing_packages"; then
                manager_log "Dependencies installed successfully"
                return 0
            else
                manager_error "Failed to auto-install dependencies"
            fi
        fi
        
        # Show manual installation instructions
        manager_error "Please install missing tools manually:"
        manager_info "  Ubuntu/Debian: sudo apt-get install$missing_packages"
        manager_info "  RHEL/CentOS: sudo yum install$missing_packages"
        manager_info "  Fedora: sudo dnf install$missing_packages"
        manager_info "  Alpine: sudo apk add$missing_packages"
        manager_info "  Arch: sudo pacman -S$missing_packages"
        manager_info "  openSUSE: sudo zypper install$missing_packages"
        manager_info "  macOS: brew install$missing_packages"
        return 1
    fi
    
    manager_debug "All requirements satisfied"
    return 0
}

# Create XDG Base Directory compliant directories
manager_create_xdg_dirs() {
    local tech_name="$MANAGER_TECH_NAME"
    
    if [ -z "$tech_name" ]; then
        manager_error "MANAGER_TECH_NAME not set"
        return 1
    fi
    
    manager_debug "Creating XDG directories for $tech_name"
    
    # Create base XDG directories
    mkdir -p "$MANAGER_XDG_CONFIG_HOME" || return 1
    mkdir -p "$MANAGER_XDG_DATA_HOME" || return 1
    mkdir -p "$MANAGER_XDG_STATE_HOME" || return 1
    mkdir -p "$MANAGER_XDG_CACHE_HOME" || return 1
    
    # Create technology-specific directories
    mkdir -p "$MANAGER_XDG_CONFIG_HOME/$tech_name" || return 1
    mkdir -p "$MANAGER_XDG_DATA_HOME/$tech_name" || return 1
    mkdir -p "$MANAGER_XDG_STATE_HOME/$tech_name" || return 1
    mkdir -p "$MANAGER_XDG_CACHE_HOME/$tech_name" || return 1
    
    # Update global variables for the technology
    MANAGER_CONFIG_DIR="$MANAGER_XDG_CONFIG_HOME/$tech_name"
    MANAGER_DATA_DIR="$MANAGER_XDG_DATA_HOME/$tech_name"
    MANAGER_STATE_DIR="$MANAGER_XDG_STATE_HOME/$tech_name"
    MANAGER_CACHE_DIR="$MANAGER_XDG_CACHE_HOME/$tech_name"
    
    manager_debug "XDG directories created successfully"
    return 0
}

# Validate input (basic sanitization) - POSIX compliant
manager_validate_input() {
    local input="$1"
    local type="${2:-string}"
    
    case "$type" in
        path)
            # Check for directory traversal attempts (POSIX pattern matching)
            case "$input" in
                *../*|*/../*|../*|*/..)
                    manager_error "Invalid path (contains ..): $input"
                    return 1
                    ;;
            esac
            ;;
        url)
            case "$input" in
                http://*|https://*)
                    # Basic URL validation
                    ;;
                *)
                    manager_error "Invalid URL (must start with http:// or https://): $input"
                    return 1
                    ;;
            esac
            ;;
        email)
            case "$input" in
                *@*.*)
                    # Basic email validation
                    ;;
                *)
                    manager_error "Invalid email format: $input"
                    return 1
                    ;;
            esac
            ;;
    esac
    
    return 0
}

# Safe temp file creation (POSIX compliant)
manager_create_temp_file() {
    local prefix="${1:-manager}"
    local temp_file
    
    if command -v mktemp >/dev/null 2>&1; then
        # Try mktemp first (available on most systems)
        temp_file=$(mktemp -t "${prefix}.XXXXXX" 2>/dev/null) || temp_file=""
    fi
    
    if [ -z "$temp_file" ]; then
        # Fallback for systems without mktemp
        temp_file="/tmp/${prefix}.$$"
        # Use process ID for uniqueness
        if ! touch "$temp_file" 2>/dev/null; then
            manager_error "Failed to create temporary file"
            return 1
        fi
        chmod 600 "$temp_file" || return 1
    fi
    
    printf '%s\n' "$temp_file"
    return 0
}

# Check if running with appropriate privileges
manager_check_privileges() {
    local dir="${1:-$MANAGER_INSTALL_DIR}"
    
    if [ -w "$dir" ] 2>/dev/null; then
        return 0  # Have write access
    elif sudo -n true 2>/dev/null; then
        return 1  # Need sudo but have it
    else
        return 2  # Need sudo but don't have it
    fi
}

# Execute command with appropriate privileges
manager_exec_privileged() {
    local dir="$1"
    shift
    
    case "$(manager_check_privileges "$dir")" in
        0)
            # Direct execution
            "$@"
            ;;
        1)
            # Use sudo
            sudo "$@"
            ;;
        *)
            manager_error "Insufficient privileges to write to $dir"
            return 1
            ;;
    esac
}

# Get current user (works even with sudo) - POSIX compliant
manager_get_user() {
    # Try different methods in order of preference
    if [ -n "$SUDO_USER" ]; then
        printf '%s\n' "$SUDO_USER"
    elif [ -n "$USER" ]; then
        printf '%s\n' "$USER"
    elif [ -n "$LOGNAME" ]; then
        printf '%s\n' "$LOGNAME"
    elif command -v whoami >/dev/null 2>&1; then
        whoami
    elif command -v id >/dev/null 2>&1; then
        id -un 2>/dev/null || printf 'unknown\n'
    else
        printf 'unknown\n'
    fi
}

# Get user home directory (works even with sudo) - POSIX compliant
manager_get_user_home() {
    local user
    user=$(manager_get_user)
    
    if [ "$user" = "root" ]; then
        printf '/root\n'
    elif [ "$user" = "unknown" ]; then
        # Fallback to current HOME or /tmp
        printf '%s\n' "${HOME:-/tmp}"
    else
        # Use getent if available for accurate home directory
        if command -v getent >/dev/null 2>&1; then
            getent passwd "$user" 2>/dev/null | cut -d: -f6 || printf '%s\n' "${HOME:-/tmp}"
        else
            # Fallback - construct typical path
            printf '/home/%s\n' "$user"
        fi
    fi
}