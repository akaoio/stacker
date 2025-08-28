#!/bin/sh
# Simple daemon uninstallation using manager framework

set -e

# Stacker framework setup
STACKER_DIR="$(dirname "$0")/../../"
. "$STACKER_DIR/stacker.sh"

# Display header
echo "=================================================="
echo "  Simple Daemon - Uninstallation"
echo "  Using @akaoio/stacker framework"
echo "=================================================="
echo ""

# Initialize manager for this technology
stacker_init "simple-daemon" \
             "https://github.com/example/simple-daemon.git" \
             "simple-daemon.sh" \
             "Example daemon service"

# Parse command line arguments
KEEP_CONFIG=false
KEEP_DATA=false

for arg in "$@"; do
    case "$arg" in
        --keep-config)
            KEEP_CONFIG=true
            ;;
        --keep-data)
            KEEP_DATA=true
            ;;
        --help|-h)
            cat << 'EOF'
Simple Daemon Uninstallation

Options:
  --keep-config    Keep configuration files
  --keep-data      Keep data and log files
  --help          Show this help

Examples:
  ./uninstall.sh                    # Complete removal
  ./uninstall.sh --keep-config      # Remove but keep config
  ./uninstall.sh --keep-data        # Remove but keep data

EOF
            exit 0
            ;;
        *)
            echo "Warning: Unknown option $arg"
            ;;
    esac
done

# Build uninstallation arguments
UNINSTALL_ARGS=""
[ "$KEEP_CONFIG" = true ] && UNINSTALL_ARGS="$UNINSTALL_ARGS --keep-config"
[ "$KEEP_DATA" = true ] && UNINSTALL_ARGS="$UNINSTALL_ARGS --keep-data"

# Confirm uninstallation
echo "This will uninstall simple-daemon:"
echo "  ✓ Stop and remove systemd service"
echo "  ✓ Remove cron jobs"
echo "  ✓ Remove installed binary"
echo "  ✓ Remove clean clone directory"
[ "$KEEP_CONFIG" = false ] && echo "  ✓ Remove configuration files"
[ "$KEEP_DATA" = false ] && echo "  ✓ Remove data and log files"
echo ""

printf "Are you sure you want to continue? [y/N]: "
read -r confirm

case "$confirm" in
    [Yy]|[Yy][Ee][Ss])
        # Proceed with uninstallation
        ;;
    *)
        echo "Uninstallation cancelled."
        exit 0
        ;;
esac

echo ""
stacker_log "Starting uninstallation..."

# Stop daemon if it's running
if [ -x "/usr/local/bin/simple-daemon" ]; then
    /usr/local/bin/simple-daemon stop 2>/dev/null || true
fi

# Run uninstallation
stacker_uninstall $UNINSTALL_ARGS

echo ""
echo "=================================================="
echo "  Simple Daemon Uninstallation Complete!"
echo "=================================================="
echo ""

if [ "$KEEP_CONFIG" = true ] || [ "$KEEP_DATA" = true ]; then
    echo "Preserved files:"
    [ "$KEEP_CONFIG" = true ] && echo "  Config: ~/.config/simple-daemon/"
    [ "$KEEP_DATA" = true ] && echo "  Data:   ~/.local/share/simple-daemon/"
    [ "$KEEP_DATA" = true ] && echo "  State:  ~/.local/state/simple-daemon/"
    echo ""
fi

echo "Simple daemon has been completely removed from your system."