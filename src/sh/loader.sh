#!/bin/sh
# @akaoio/stacker - Dynamic Module Loading System
# PURE POSIX shell implementation for selective module loading

# Module registry - tracks loaded modules
STACKER_LOADED_MODULES=""

# Check if module is already loaded
stacker_is_module_loaded() {
    local module_name="$1"
    case " $STACKER_LOADED_MODULES " in
        *" $module_name "*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Mark module as loaded
stacker_mark_module_loaded() {
    local module_name="$1"
    if ! stacker_is_module_loaded "$module_name"; then
        STACKER_LOADED_MODULES="$STACKER_LOADED_MODULES $module_name"
    fi
}

# Get module dependencies
stacker_get_module_dependencies() {
    local module_name="$1"
    
    # Direct case mapping for dependencies (POSIX compliant)
    case "$module_name" in
        core) echo "" ;;
        config) echo "core" ;;
        install) echo "core config" ;;
        service) echo "core config" ;;
        update) echo "core config" ;;
        self) echo "core" ;;
        cli) echo "core config" ;;
        package) echo "core" ;;
        *) echo "" ;;
    esac
}

# Load a single module with dependency resolution
stacker_load_module() {
    local module_name="$1"
    local module_file="$STACKER_DIR/src/sh/module/${module_name}.sh"
    
    # Skip if already loaded
    if stacker_is_module_loaded "$module_name"; then
        return 0
    fi
    
    # Check module exists
    if [ ! -f "$module_file" ]; then
        # Special case: look for legacy module files in root
        local legacy_file="$STACKER_DIR/stacker-${module_name}.sh"
        if [ -f "$legacy_file" ]; then
            module_file="$legacy_file"
        else
            stacker_error "Module not found: $module_name (tried $module_file and $legacy_file)"
            return 1
        fi
    fi
    
    # Load dependencies first (recursive)
    local deps dep
    deps=$(stacker_get_module_dependencies "$module_name")
    for dep in $deps; do
        if ! stacker_load_module "$dep"; then
            stacker_error "Failed to load dependency '$dep' for module '$module_name'"
            return 1
        fi
    done
    
    # Source the module file
    if ! . "$module_file"; then
        stacker_error "Failed to source module: $module_file"
        return 1
    fi
    
    # Mark as loaded
    stacker_mark_module_loaded "$module_name"
    
    # Call module initialization if it exists
    local init_func="${module_name}_init"
    if command -v "$init_func" >/dev/null 2>&1; then
        if ! "$init_func"; then
            stacker_error "Module initialization failed: $module_name"
            return 1
        fi
    fi
    
    stacker_debug "Loaded module: $module_name"
    return 0
}

# Load multiple modules
stacker_load_modules() {
    local all_modules="$*"
    local module
    
    # Handle space-separated list
    for module in $all_modules; do
        if ! stacker_load_module "$module"; then
            return 1
        fi
    done
}

# Require modules (alias for load_modules for better readability)
stacker_require() {
    stacker_load_modules "$@"
}

# List all available modules
stacker_list_available_modules() {
    local modules_dir="$STACKER_DIR/src/sh/module"
    local module_file module_name
    
    echo "Available modules:"
    
    # List modules in src/sh/module/ directory
    if [ -d "$modules_dir" ]; then
        for module_file in "$modules_dir"/*.sh; do
            if [ -f "$module_file" ]; then
                module_name=$(basename "$module_file" .sh)
                echo "  $module_name"
            fi
        done
    fi
    
    # List legacy modules in root directory
    for module_file in "$STACKER_DIR"/stacker-*.sh; do
        if [ -f "$module_file" ]; then
            module_name=$(basename "$module_file" .sh)
            module_name="${module_name#stacker-}"
            echo "  $module_name (legacy)"
        fi
    done
}

# List loaded modules
stacker_list_loaded_modules() {
    echo "Loaded modules: $STACKER_LOADED_MODULES"
}

# Get module info
stacker_module_info() {
    local module_name="$1"
    local deps
    
    if [ -z "$module_name" ]; then
        stacker_error "Module name required"
        return 1
    fi
    
    deps=$(stacker_get_module_dependencies "$module_name")
    
    echo "Module: $module_name"
    echo "Dependencies: ${deps:-none}"
    
    if stacker_is_module_loaded "$module_name"; then
        echo "Status: loaded"
    else
        echo "Status: not loaded"
    fi
}

# Auto-load modules based on function call
stacker_autoload_for_function() {
    local func_name="$1"
    
    # Map function prefixes to modules
    case "$func_name" in
        stacker_config_*|stacker_load_config|stacker_save_config|stacker_get_config|stacker_set_config)
            stacker_require "config"
            ;;
        stacker_install*|stacker_create_clean_clone|stacker_setup_*|stacker_uninstall*)
            stacker_require "install"
            ;;
        stacker_service*|stacker_systemd_*|stacker_cron_*)
            stacker_require "service"
            ;;
        stacker_update*|stacker_check_updates|stacker_rollback*|stacker_cli_update|stacker_cli_rollback|stacker_cli_self_update)
            stacker_require "update"
            ;;
        stacker_cli_self_install|stacker_cli_self_uninstall)
            stacker_require "self"
            ;;
        stacker_cli_*|stacker_parse_cli)
            stacker_require "cli"
            ;;
        stacker_*_package*|stacker_cli_add|stacker_cli_remove|stacker_cli_list|stacker_cli_enable|stacker_cli_disable|stacker_cli_search|stacker_cli_info)
            stacker_require "package"
            ;;
        *)
            # Default to core for unknown functions
            stacker_require "core"
            ;;
    esac
}

# Smart function wrapper that auto-loads modules
stacker_smart_call() {
    local func_name="$1"
    shift
    
    # Try to call the function
    if command -v "$func_name" >/dev/null 2>&1; then
        "$func_name" "$@"
        return $?
    fi
    
    # Function not found, try auto-loading appropriate module
    stacker_autoload_for_function "$func_name"
    
    # Try calling again
    if command -v "$func_name" >/dev/null 2>&1; then
        "$func_name" "$@"
        return $?
    else
        stacker_error "Function not found even after auto-loading: $func_name"
        return 1
    fi
}

# Initialize the loader (always load core)
stacker_loader_init() {
    # Core is always required
    stacker_require "core" || {
        echo "FATAL: Cannot load core module" >&2
        return 1
    }
}

# Module loader is ready - basic functions for bootstrap
# These will be replaced by full core module functions when loaded
stacker_error() {
    # Simple bootstrap version - will be overridden by core module
    echo "ERROR: $*" >&2
}

stacker_debug() {
    # Simple bootstrap version - will be overridden by core module  
    if [ "${STACKER_DEBUG:-0}" = "1" ] || [ "${STACKER_DEBUG:-0}" = "true" ]; then
        echo "DEBUG: $*" >&2
    fi
}