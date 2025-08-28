#!/bin/sh
# @akaoio/manager - Dynamic Module Loading System
# PURE POSIX shell implementation for selective module loading

# Module registry - tracks loaded modules and dependencies
MANAGER_LOADED_MODULES=""
MANAGER_MODULE_DEPENDENCIES_core=""
MANAGER_MODULE_DEPENDENCIES_config="core"
MANAGER_MODULE_DEPENDENCIES_install="core config"
MANAGER_MODULE_DEPENDENCIES_service="core config"
MANAGER_MODULE_DEPENDENCIES_update="core config"
MANAGER_MODULE_DEPENDENCIES_self_update="core config update"
MANAGER_MODULE_DEPENDENCIES_cli="core config"

# Check if module is already loaded
manager_is_module_loaded() {
    local module_name="$1"
    case " $MANAGER_LOADED_MODULES " in
        *" $module_name "*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Mark module as loaded
manager_mark_module_loaded() {
    local module_name="$1"
    if ! manager_is_module_loaded "$module_name"; then
        MANAGER_LOADED_MODULES="$MANAGER_LOADED_MODULES $module_name"
    fi
}

# Get module dependencies
manager_get_module_dependencies() {
    local module_name="$1"
    local var_name="MANAGER_MODULE_DEPENDENCIES_${module_name}"
    
    # Use eval to get the value of the dynamically named variable
    eval "echo \${${var_name}:-}"
}

# Load a single module with dependency resolution
manager_load_module() {
    local module_name="$1"
    local module_file="$MANAGER_DIR/modules/${module_name}.sh"
    
    # Skip if already loaded
    if manager_is_module_loaded "$module_name"; then
        return 0
    fi
    
    # Check module exists
    if [ ! -f "$module_file" ]; then
        # Special case: look for legacy module files in root
        local legacy_file="$MANAGER_DIR/manager-${module_name}.sh"
        if [ -f "$legacy_file" ]; then
            module_file="$legacy_file"
        else
            manager_error "Module not found: $module_name (tried $module_file and $legacy_file)"
            return 1
        fi
    fi
    
    # Load dependencies first (recursive)
    local deps dep
    deps=$(manager_get_module_dependencies "$module_name")
    for dep in $deps; do
        if ! manager_load_module "$dep"; then
            manager_error "Failed to load dependency '$dep' for module '$module_name'"
            return 1
        fi
    done
    
    # Source the module file
    if ! . "$module_file"; then
        manager_error "Failed to source module: $module_file"
        return 1
    fi
    
    # Mark as loaded
    manager_mark_module_loaded "$module_name"
    
    # Call module initialization if it exists
    local init_func="${module_name}_init"
    if command -v "$init_func" >/dev/null 2>&1; then
        if ! "$init_func"; then
            manager_error "Module initialization failed: $module_name"
            return 1
        fi
    fi
    
    manager_debug "Loaded module: $module_name"
    return 0
}

# Load multiple modules
manager_load_modules() {
    local all_modules="$*"
    local module
    
    # Handle space-separated list
    for module in $all_modules; do
        if ! manager_load_module "$module"; then
            return 1
        fi
    done
}

# Require modules (alias for load_modules for better readability)
manager_require() {
    manager_load_modules "$@"
}

# List all available modules
manager_list_available_modules() {
    local modules_dir="$MANAGER_DIR/modules"
    local module_file module_name
    
    echo "Available modules:"
    
    # List modules in modules/ directory
    if [ -d "$modules_dir" ]; then
        for module_file in "$modules_dir"/*.sh; do
            if [ -f "$module_file" ]; then
                module_name=$(basename "$module_file" .sh)
                echo "  $module_name"
            fi
        done
    fi
    
    # List legacy modules in root directory
    for module_file in "$MANAGER_DIR"/manager-*.sh; do
        if [ -f "$module_file" ]; then
            module_name=$(basename "$module_file" .sh)
            module_name="${module_name#manager-}"
            echo "  $module_name (legacy)"
        fi
    done
}

# List loaded modules
manager_list_loaded_modules() {
    echo "Loaded modules: $MANAGER_LOADED_MODULES"
}

# Get module info
manager_module_info() {
    local module_name="$1"
    local deps
    
    if [ -z "$module_name" ]; then
        manager_error "Module name required"
        return 1
    fi
    
    deps=$(manager_get_module_dependencies "$module_name")
    
    echo "Module: $module_name"
    echo "Dependencies: ${deps:-none}"
    
    if manager_is_module_loaded "$module_name"; then
        echo "Status: loaded"
    else
        echo "Status: not loaded"
    fi
}

# Auto-load modules based on function call
manager_autoload_for_function() {
    local func_name="$1"
    
    # Map function prefixes to modules
    case "$func_name" in
        manager_config_*|manager_load_config|manager_save_config|manager_get_config|manager_set_config)
            manager_require "config"
            ;;
        manager_install*|manager_create_clean_clone|manager_setup_*|manager_uninstall*)
            manager_require "install"
            ;;
        manager_service*|manager_systemd_*|manager_cron_*)
            manager_require "service"
            ;;
        manager_update*|manager_check_updates)
            manager_require "update"
            ;;
        manager_self_update*|manager_handle_self_update)
            manager_require "self_update"
            ;;
        *)
            # Default to core for unknown functions
            manager_require "core"
            ;;
    esac
}

# Smart function wrapper that auto-loads modules
manager_smart_call() {
    local func_name="$1"
    shift
    
    # Try to call the function
    if command -v "$func_name" >/dev/null 2>&1; then
        "$func_name" "$@"
        return $?
    fi
    
    # Function not found, try auto-loading appropriate module
    manager_autoload_for_function "$func_name"
    
    # Try calling again
    if command -v "$func_name" >/dev/null 2>&1; then
        "$func_name" "$@"
        return $?
    else
        manager_error "Function not found even after auto-loading: $func_name"
        return 1
    fi
}

# Initialize the loader (always load core)
manager_loader_init() {
    # Core is always required
    manager_require "core" || {
        echo "FATAL: Cannot load core module" >&2
        return 1
    }
}

# Module loader is ready - basic error function for bootstrap
manager_error() {
    echo "ERROR: $*" >&2
}

manager_debug() {
    if [ "${MANAGER_DEBUG:-0}" = "1" ]; then
        echo "DEBUG: $*" >&2
    fi
}