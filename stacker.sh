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
        config|-c)
            shift
            stacker_require "config" || exit 1
            case "$1" in
                --help|-h|"")
                    echo "Usage: stacker config <get|set|list> [KEY] [VALUE]"
                    echo "Examples: stacker config get key, stacker config set key value"
                    ;;
                get) shift; stacker_get_config "$1" ;;
                set) shift; stacker_save_config "$1" "$2" ;;
                list) stacker_show_config ;;
                *) echo "Unknown config action: $1"; exit 1 ;;
            esac
            ;;
        install)
            shift
            if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
                echo "Usage: stacker install <package-url|stacker> [--user|--system|--local]"
                echo "Examples: stacker install gh:user/repo, stacker install stacker"
                exit 0
            fi
            
            # Handle self-installation
            if [ "$1" = "stacker" ]; then
                echo "🔄 Installing/updating Stacker framework..."
                if [ -d "$STACKER_DIR/.git" ]; then
                    cd "$STACKER_DIR" && git pull origin main
                    ./install.sh
                    echo "✅ Stacker framework updated"
                else
                    echo "Downloading latest Stacker..."
                    rm -rf /tmp/stacker-install
                    git clone https://github.com/akaoio/stacker.git /tmp/stacker-install
                    cd /tmp/stacker-install && ./install.sh
                    rm -rf /tmp/stacker-install
                    echo "✅ Stacker framework installed"
                fi
                exit 0
            fi
            
            # Check if trying to install stacker as package (redirect to self-install)
            if [ "$1" = "gh:akaoio/stacker" ] || [ "$1" = "https://github.com/akaoio/stacker.git" ]; then
                echo "🔄 Installing/updating Stacker framework..."
                if [ -d "$STACKER_DIR/.git" ]; then
                    cd "$STACKER_DIR" && git pull origin main
                    ./install.sh
                    echo "✅ Stacker framework updated"
                else
                    echo "Downloading latest Stacker..."
                    rm -rf /tmp/stacker-install
                    git clone https://github.com/akaoio/stacker.git /tmp/stacker-install
                    cd /tmp/stacker-install && ./install.sh
                    rm -rf /tmp/stacker-install
                    echo "✅ Stacker framework installed"
                fi
                exit 0
            fi
            
            stacker_require "package" || exit 1
            stacker_install_package "$@"
            ;;
        uninstall)
            shift
            if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
                echo "Usage: stacker uninstall <package-name|stacker> [--user|--system|--local]"
                echo "Examples: stacker uninstall air, stacker uninstall stacker"
                exit 0
            fi
            
            # Handle self-uninstallation
            if [ "$1" = "stacker" ]; then
                echo "⚠️  WARNING: This will remove Stacker framework completely!"
                printf "Are you sure? [y/N]: "
                read -r confirm
                case "$confirm" in
                    [yY]|[yY][eE][sS])
                        echo "🗑️ Removing Stacker framework..."
                        rm -rf ~/.local/share/stacker/
                        rm -f ~/.local/bin/stacker
                        rm -rf ~/.config/stacker/
                        echo "✅ Stacker framework removed completely"
                        echo "To reinstall: curl -sSL https://raw.githubusercontent.com/akaoio/stacker/main/install.sh | sh"
                        ;;
                    *)
                        echo "Cancelled"
                        ;;
                esac
                exit 0
            fi
            
            stacker_require "package" || exit 1
            stacker_remove_package "$@"
            ;;
        update|-u)
            shift
            if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
                echo "Usage: stacker update [stacker|package-name|<empty for all>]"
                exit 0
            fi
            stacker_require "update" || exit 1  
            stacker_cli_update "$@"
            ;;
        list|ls)
            shift
            if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
                echo "Usage: stacker list [--user|--system|--local|--all]"
                exit 0
            fi
            stacker_require "package" || exit 1
            if [ "$1" = "--all" ]; then
                for scope in local user system; do
                    stacker_list_packages "$scope"
                done
            else
                stacker_list_packages "${1:-user}"
            fi
            ;;
        service|daemon|watchdog)
            echo "$1 management not implemented"
            echo "Use: stacker install <package> for package installation"
            exit 1
            ;;
        rollback|-r)
            shift
            if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
                echo "Usage: stacker rollback [version]"
                exit 0
            fi
            stacker_require "update" || exit 1
            stacker_cli_rollback "$@"
            ;;
        enable|disable)
            echo "$1 command not implemented"
            echo "Packages are enabled automatically when installed"
            exit 1
            ;;
        search)
            shift
            if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
                echo "Usage: stacker search <query>"
                exit 0
            fi
            stacker_require "package" || exit 1
            stacker_search_packages "$@"
            ;;
        info)
            shift
            if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
                echo "Usage: stacker info <package-name> [--user|--system|--local]"
                exit 0
            fi
            stacker_require "package" || exit 1
            stacker_package_info "$@"
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
if [ "${0##*/}" = "stacker.sh" ] || [ "${0##*/}" = "stacker" ]; then
    stacker_parse_cli "$@"
fi