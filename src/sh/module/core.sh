#!/bin/sh
# Module: core
# Description: Core utilities and logging functions for Stacker framework
# Dependencies: none
# Provides: logging, OS detection, validation, XDG directories, privilege handling

# Module metadata
STACKER_MODULE_NAME="core"
STACKER_MODULE_VERSION="1.0.0"
STACKER_MODULE_DEPENDENCIES=""
STACKER_MODULE_LOADED=false

# XDG Base Directory Specification compliance
STACKER_XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STACKER_XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" 
STACKER_XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STACKER_XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Stacker framework XDG directories
STACKER_CONFIG_DIR="$STACKER_XDG_CONFIG_HOME/stacker"
STACKER_DATA_DIR="$STACKER_XDG_DATA_HOME/stacker"
STACKER_STATE_DIR="$STACKER_XDG_STATE_HOME/stacker"
STACKER_CACHE_DIR="$STACKER_XDG_CACHE_HOME/stacker"

# Colors for output (POSIX compliant terminal detection)
# Check for NO_COLOR environment variable first (https://no-color.org/)
if [ "${NO_COLOR:-0}" = "1" ] || [ "${FORCE_COLOR:-0}" = "0" ]; then
    STACKER_RED=''
    STACKER_GREEN=''
    STACKER_YELLOW=''
    STACKER_BLUE=''
    STACKER_NC=''
elif [ "${FORCE_COLOR:-0}" = "1" ] || { [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; }; then
    # Use colors if forced or if stdout is a terminal and TERM is not dumb
    STACKER_RED='\033[0;31m'
    STACKER_GREEN='\033[0;32m' 
    STACKER_YELLOW='\033[1;33m'
    STACKER_BLUE='\033[0;34m'
    STACKER_NC='\033[0m'
else
    STACKER_RED=''
    STACKER_GREEN=''
    STACKER_YELLOW=''
    STACKER_BLUE=''
    STACKER_NC=''
fi

# Module initialization
core_init() {
    STACKER_MODULE_LOADED=true
    stacker_debug "Core module initialized"
    return 0
}

# Logging functions with XDG-compliant log file
stacker_get_log_file() {
    if [ -n "$STACKER_TECH_NAME" ]; then
        echo "$STACKER_XDG_DATA_HOME/$STACKER_TECH_NAME/stacker.log"
    else
        echo "$STACKER_DATA_DIR/stacker.log"
    fi
}

stacker_log_to_file() {
    local log_file
    log_file=$(stacker_get_log_file)
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
    
    # Log with timestamp (POSIX date format)
    printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$log_file" 2>/dev/null || true
}

stacker_log() {
    # Use echo -e if available and colors are set, otherwise printf
    if [ -n "$STACKER_GREEN" ] && echo -e test >/dev/null 2>&1; then
        echo -e "${STACKER_GREEN}[Stacker]${STACKER_NC} $*"
    else
        printf "%s[Stacker]%s %s\n" "$STACKER_GREEN" "$STACKER_NC" "$*"
    fi
    stacker_log_to_file "LOG: $*"
}

stacker_info() {
    if [ -n "$STACKER_BLUE" ] && echo -e test >/dev/null 2>&1; then
        echo -e "${STACKER_BLUE}[Info]${STACKER_NC} $*"
    else
        printf "%s[Info]%s %s\n" "$STACKER_BLUE" "$STACKER_NC" "$*"
    fi
    stacker_log_to_file "INFO: $*"
}

stacker_warn() {
    if [ -n "$STACKER_YELLOW" ] && echo -e test >/dev/null 2>&1; then
        echo -e "${STACKER_YELLOW}[Warning]${STACKER_NC} $*" >&2
    else
        printf "%s[Warning]%s %s\n" "$STACKER_YELLOW" "$STACKER_NC" "$*" >&2
    fi
    stacker_log_to_file "WARN: $*"
}

stacker_error() {
    if [ -n "$STACKER_RED" ] && echo -e test >/dev/null 2>&1; then
        echo -e "${STACKER_RED}[Error]${STACKER_NC} $*" >&2
    else
        printf "%s[Error]%s %s\n" "$STACKER_RED" "$STACKER_NC" "$*" >&2
    fi
    stacker_log_to_file "ERROR: $*"
}

# Debug logging (controlled by STACKER_DEBUG environment variable)
stacker_debug() {
    if [ "$STACKER_DEBUG" = "1" ] || [ "$STACKER_DEBUG" = "true" ]; then
        printf "%s[Debug]%s %s\n" "$STACKER_BLUE" "$STACKER_NC" "$*" >&2
        stacker_log_to_file "DEBUG: $*"
    fi
}

# POSIX-compliant case conversion functions
stacker_to_upper() {
    printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'
}

stacker_to_lower() {
    printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]'
}

# OS and package stacker detection (POSIX compliant)
stacker_detect_os() {
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

stacker_detect_package_stacker() {
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
stacker_auto_install_deps() {
    local packages="$1"
    local pm
    
    if [ -z "$packages" ]; then
        return 0
    fi
    
    pm=$(stacker_detect_package_stacker)
    stacker_debug "Detected package stacker: $pm"
    
    case "$pm" in
        apt)
            stacker_log "Installing packages with apt: $packages"
            if sudo -n true 2>/dev/null; then
                sudo apt-get update >/dev/null 2>&1 || return 1
                # Use word splitting intentionally for packages
                # shellcheck disable=SC2086
                sudo apt-get install -y $packages >/dev/null 2>&1 || return 1
            else
                stacker_error "apt requires sudo privileges"
                return 1
            fi
            ;;
        yum)
            stacker_log "Installing packages with yum: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo yum install -y $packages >/dev/null 2>&1 || return 1
            else
                stacker_error "yum requires sudo privileges"
                return 1
            fi
            ;;
        dnf)
            stacker_log "Installing packages with dnf: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo dnf install -y $packages >/dev/null 2>&1 || return 1
            else
                stacker_error "dnf requires sudo privileges"
                return 1
            fi
            ;;
        apk)
            stacker_log "Installing packages with apk: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo apk add --no-cache $packages >/dev/null 2>&1 || return 1
            else
                stacker_error "apk requires sudo privileges"
                return 1
            fi
            ;;
        brew)
            stacker_log "Installing packages with brew: $packages"
            # Homebrew typically doesn't need sudo
            # shellcheck disable=SC2086
            brew install $packages >/dev/null 2>&1 || return 1
            ;;
        pkg)
            stacker_log "Installing packages with pkg: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo pkg install -y $packages >/dev/null 2>&1 || return 1
            else
                stacker_error "pkg requires sudo privileges"
                return 1
            fi
            ;;
        pacman)
            stacker_log "Installing packages with pacman: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo pacman -S --noconfirm $packages >/dev/null 2>&1 || return 1
            else
                stacker_error "pacman requires sudo privileges"
                return 1
            fi
            ;;
        zypper)
            stacker_log "Installing packages with zypper: $packages"
            if sudo -n true 2>/dev/null; then
                # shellcheck disable=SC2086
                sudo zypper install -y $packages >/dev/null 2>&1 || return 1
            else
                stacker_error "zypper requires sudo privileges"
                return 1
            fi
            ;;
        *)
            stacker_error "No supported package stacker found"
            return 1
            ;;
    esac
    
    stacker_log "Successfully installed: $packages"
    return 0
}

# Check for required tools and auto-install if possible (POSIX compliant)
stacker_check_requirements() {
    local missing=""
    local missing_packages=""
    local arg1 arg2
    
    stacker_debug "Checking requirements..."
    
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
        stacker_warn "Missing required tools:$missing"
        
        # Try auto-install if we have sudo
        if sudo -n true 2>/dev/null || [ "$(id -u)" -eq 0 ]; then
            stacker_log "Attempting to auto-install missing dependencies..."
            if stacker_auto_install_deps "$missing_packages"; then
                stacker_log "Dependencies installed successfully"
                return 0
            else
                stacker_error "Failed to auto-install dependencies"
            fi
        fi
        
        # Show manual installation instructions
        stacker_error "Please install missing tools manually:"
        stacker_info "  Ubuntu/Debian: sudo apt-get install$missing_packages"
        stacker_info "  RHEL/CentOS: sudo yum install$missing_packages"
        stacker_info "  Fedora: sudo dnf install$missing_packages"
        stacker_info "  Alpine: sudo apk add$missing_packages"
        stacker_info "  Arch: sudo pacman -S$missing_packages"
        stacker_info "  openSUSE: sudo zypper install$missing_packages"
        stacker_info "  macOS: brew install$missing_packages"
        return 1
    fi
    
    stacker_debug "All requirements satisfied"
    return 0
}

# Create XDG Base Directory compliant directories
stacker_create_xdg_dirs() {
    local tech_name="$STACKER_TECH_NAME"
    
    if [ -z "$tech_name" ]; then
        stacker_error "STACKER_TECH_NAME not set"
        return 1
    fi
    
    stacker_debug "Creating XDG directories for $tech_name"
    
    # Create base XDG directories
    mkdir -p "$STACKER_XDG_CONFIG_HOME" || return 1
    mkdir -p "$STACKER_XDG_DATA_HOME" || return 1
    mkdir -p "$STACKER_XDG_STATE_HOME" || return 1
    mkdir -p "$STACKER_XDG_CACHE_HOME" || return 1
    
    # Create technology-specific directories
    mkdir -p "$STACKER_XDG_CONFIG_HOME/$tech_name" || return 1
    mkdir -p "$STACKER_XDG_DATA_HOME/$tech_name" || return 1
    mkdir -p "$STACKER_XDG_STATE_HOME/$tech_name" || return 1
    mkdir -p "$STACKER_XDG_CACHE_HOME/$tech_name" || return 1
    
    # Update global variables for the technology
    STACKER_CONFIG_DIR="$STACKER_XDG_CONFIG_HOME/$tech_name"
    STACKER_DATA_DIR="$STACKER_XDG_DATA_HOME/$tech_name"
    STACKER_STATE_DIR="$STACKER_XDG_STATE_HOME/$tech_name"
    STACKER_CACHE_DIR="$STACKER_XDG_CACHE_HOME/$tech_name"
    
    stacker_debug "XDG directories created successfully"
    return 0
}

# Validate input (basic sanitization) - POSIX compliant
stacker_validate_input() {
    local input="$1"
    local type="${2:-string}"
    
    case "$type" in
        path)
            # Check for directory traversal attempts (POSIX pattern matching)
            case "$input" in
                *../*|*/../*|../*|*/..)
                    stacker_error "Invalid path (contains ..): $input"
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
                    stacker_error "Invalid URL (must start with http:// or https://): $input"
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
                    stacker_error "Invalid email format: $input"
                    return 1
                    ;;
            esac
            ;;
    esac
    
    return 0
}

# Safe temp file creation (POSIX compliant)
stacker_create_temp_file() {
    local prefix="${1:-stacker}"
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
            stacker_error "Failed to create temporary file"
            return 1
        fi
        chmod 600 "$temp_file" || return 1
    fi
    
    printf '%s\n' "$temp_file"
    return 0
}

# Check if running with appropriate privileges
stacker_check_privileges() {
    local dir="${1:-$STACKER_INSTALL_DIR}"
    
    # If directory doesn't exist, check parent directory
    if [ ! -d "$dir" ]; then
        # Create directory if in user space
        case "$dir" in
            "$HOME"/*|"$HOME")
                mkdir -p "$dir" 2>/dev/null && echo "0" && return
                ;;
        esac
        # Check parent directory for system paths
        dir="$(dirname "$dir")"
    fi
    
    if [ -w "$dir" ] 2>/dev/null; then
        echo "0"  # Have write access
    elif sudo -n true 2>/dev/null; then
        echo "1"  # Need sudo but have it
    else
        echo "2"  # Need sudo but don't have it
    fi
}

# Execute command with appropriate privileges
stacker_exec_privileged() {
    local dir="$1"
    shift
    
    local priv_level
    priv_level=$(stacker_check_privileges "$dir")
    stacker_debug "Checking privileges for $dir: level=$priv_level"
    
    case "$priv_level" in
        0)
            # Direct execution
            stacker_debug "Direct execution: $*"
            "$@"
            ;;
        1)
            # Use sudo
            stacker_debug "Sudo execution: $*"
            sudo "$@"
            ;;
        *)
            stacker_error "Insufficient privileges to write to $dir"
            return 1
            ;;
    esac
}

# Get current user (works even with sudo) - POSIX compliant
stacker_get_user() {
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
stacker_get_user_home() {
    local user
    user=$(stacker_get_user)
    
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

# Universal argument parsing utilities
# Standardizes common argument patterns across all modules

# Standard error messages
STACKER_ERR_UNKNOWN_OPTION="Unknown option for"
STACKER_ERR_MISSING_ARG="Missing required argument for"
STACKER_ERR_INVALID_VALUE="Invalid value for option"

# Universal argument parser helper
# Usage: stacker_parse_common_args "command_name" "$@"
stacker_parse_common_args() {
    local command_name="$1"
    shift
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                stacker_show_command_help "$command_name"
                return 0
                ;;
            --version|-v)
                echo "$STACKER_VERSION"
                return 0
                ;;
            --debug)
                STACKER_DEBUG=true
                shift
                ;;
            --quiet|-q)
                STACKER_QUIET=true
                shift
                ;;
            --)
                shift
                break
                ;;
            --*)
                # Unknown long option - let command handle it
                break
                ;;
            -*)
                # Unknown short option - let command handle it  
                break
                ;;
            *)
                # Non-option argument - let command handle it
                break
                ;;
        esac
    done
    
    # Return remaining arguments for command-specific parsing
    return 0
}

# Standardized error for unknown options
stacker_unknown_option_error() {
    local command_name="$1"
    local option="$2"
    stacker_error "$STACKER_ERR_UNKNOWN_OPTION $command_name: $option"
}

# Standardized error for missing arguments
stacker_missing_arg_error() {
    local option="$1"
    stacker_error "$STACKER_ERR_MISSING_ARG $option"
}

# Standardized error for invalid values
stacker_invalid_value_error() {
    local option="$1"
    local value="$2"
    stacker_error "$STACKER_ERR_INVALID_VALUE $option: $value"
}

# Common argument parsing pattern
# Usage: stacker_standard_args_loop "command_name" valid_options_array "$@"
stacker_standard_args_loop() {
    local command_name="$1"
    shift
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                stacker_show_command_help "$command_name"
                return 0
                ;;
            --version|-v)
                echo "$STACKER_VERSION"
                return 0
                ;;
            --debug)
                STACKER_DEBUG=true
                shift
                ;;
            --quiet|-q)
                STACKER_QUIET=true
                shift
                ;;
            --)
                shift
                break
                ;;
            --*|-*)
                stacker_unknown_option_error "$command_name" "$1"
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
}

# Show command help (placeholder for future help system)
stacker_show_command_help() {
    local command_name="$1"
    echo "Help for $command_name command"
    echo "Use: stacker $command_name --help for detailed information"
}

# Shared argument parsing utility for help options
stacker_parse_help_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                return 0  # Help requested
                ;;
            *)
                return 1  # No help requested
                ;;
        esac
        shift
    done
    return 1
}

# Shared argument parsing utility for common options
stacker_parse_common_options() {
    local verbose=false
    local debug=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose|-v)
                verbose=true
                export STACKER_VERBOSE=1
                ;;
            --debug|-d)
                debug=true
                export STACKER_DEBUG=1
                ;;
            --no-color)
                export NO_COLOR=1
                ;;
            --force-color)
                export FORCE_COLOR=1
                ;;
            *)
                # Return remaining args
                echo "$*"
                return 0
                ;;
        esac
        shift
    done
    
    echo ""
}

# Shared help formatter utility
stacker_format_help() {
    local command="$1"
    local description="$2"
    local usage="$3"
    local options="$4"
    local examples="$5"
    
    printf "Usage: stacker %s %s\n\n%s\n\n" "$command" "$usage" "$description"
    
    if [ -n "$options" ]; then
        printf "Options:\n%s\n\n" "$options"
    fi
    
    if [ -n "$examples" ]; then
        printf "Examples:\n%s\n\n" "$examples"
    fi
}

# Export public interface
core_list_functions() {
    echo "stacker_log stacker_info stacker_warn stacker_error stacker_debug"
    echo "stacker_detect_os stacker_detect_package_stacker stacker_check_requirements"
    echo "stacker_parse_help_args stacker_parse_common_options stacker_format_help"
    echo "stacker_create_xdg_dirs stacker_validate_input stacker_create_temp_file"
    echo "stacker_check_privileges stacker_exec_privileged stacker_get_user stacker_get_user_home"
    echo "stacker_to_upper stacker_to_lower stacker_auto_install_deps"
    echo "stacker_parse_common_args stacker_standard_args_loop stacker_show_command_help"
    echo "stacker_unknown_option_error stacker_missing_arg_error stacker_invalid_value_error"
}