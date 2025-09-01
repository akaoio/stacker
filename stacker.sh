#!/bin/sh
# @akaoio/stacker - Universal Shell Framework
# Modular Architecture Entry Point

# Framework directory detection
if [ -z "$STACKER_DIR" ]; then
    STACKER_DIR="$(dirname "$0")"
fi

# Framework version - single source of truth
if [ -f "$STACKER_DIR/VERSION" ]; then
    STACKER_VERSION=$(cat "$STACKER_DIR/VERSION")
else
    STACKER_VERSION="0.0.1"  # Fallback
fi

# Load the module loading system first
. "$STACKER_DIR/src/sh/loader.sh" || {
    echo "FATAL: Cannot load module loader" >&2
    exit 1
}

# Initialize the loader (loads core module)
stacker_loader_init || {
    echo "FATAL: Cannot initialize module loader" >&2
    exit 1
}

# CLI dispatcher - delegates to module functions
stacker_parse_cli() {
    case "$1" in
        --help|-h|help)
            stacker_require "cli" || exit 1
            stacker_help
            exit 0
            ;;
        --version|-v|version)
            stacker_require "cli" || exit 1
            local json_output=false
            [ "$2" = "--json" ] && json_output=true
            if [ "$json_output" = true ]; then
                echo "{\"version\":\"$STACKER_VERSION\",\"type\":\"modular\",\"loaded_modules\":\"$STACKER_LOADED_MODULES\"}"
            else
                stacker_version
            fi
            exit 0
            ;;
        --list-modules|-l)
            stacker_list_loaded_modules
            echo ""
            stacker_list_available_modules
            exit 0
            ;;
        --module-info|-m)
            [ -n "$2" ] || { echo "Usage: stacker --module-info MODULE_NAME"; exit 1; }
            stacker_module_info "$2"
            exit 0
            ;;
        init|-i)
            shift
            stacker_smart_call stacker_cli_init "$@"
            ;;
        config|-c)
            shift
            stacker_smart_call stacker_cli_config "$@"
            ;;
        install)
            shift
            stacker_smart_call stacker_cli_install "$@"
            ;;
        update|-u)
            shift  
            stacker_smart_call stacker_cli_update "$@"
            ;;
        service|-s)
            shift
            stacker_smart_call stacker_cli_service "$@"
            ;;
        health)
            shift
            stacker_smart_call stacker_cli_health "$@"
            ;;
        status)
            stacker_smart_call stacker_cli_status "$@"
            ;;
        rollback|-r)
            shift
            stacker_smart_call stacker_cli_rollback "$@"
            ;;
        add)
            shift
            stacker_smart_call stacker_cli_add "$@"
            ;;
        remove|rm)
            shift
            stacker_smart_call stacker_cli_remove "$@"
            ;;
        list|ls)
            shift
            stacker_smart_call stacker_cli_list "$@"
            ;;
        enable)
            shift
            stacker_smart_call stacker_cli_enable "$@"
            ;;
        disable)
            shift
            stacker_smart_call stacker_cli_disable "$@"
            ;;
        search)
            shift
            stacker_smart_call stacker_cli_search "$@"
            ;;
        info)
            shift
            stacker_smart_call stacker_cli_info "$@"
            ;;
        "")
            stacker_require "cli" || exit 1
            stacker_help
            exit 0
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'stacker --help' for usage information"
            exit 1
            ;;
    esac
}

# If script is executed (not sourced), run CLI
if [ "${0##*/}" = "stacker.sh" ]; then
    stacker_parse_cli "$@"
fi