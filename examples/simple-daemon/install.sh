#!/bin/sh
# Simple daemon installation example using manager framework

set -e

# Stacker framework setup
STACKER_DIR="$(dirname "$0")/../../"
. "$STACKER_DIR/stacker.sh"

# Display header
echo "=================================================="
echo "  Simple Daemon - Example Installation"
echo "  Using @akaoio/stacker framework"
echo "=================================================="
echo ""

# Initialize manager for this technology
stacker_init "simple-daemon" \
             "https://github.com/example/simple-daemon.git" \
             "simple-daemon.sh" \
             "Example daemon service"

# Parse command line arguments
USE_SERVICE=false
USE_CRON=false
USE_AUTO_UPDATE=false
CRON_INTERVAL=5
SHOW_HELP=false

for arg in "$@"; do
    case "$arg" in
        --service|--systemd)
            USE_SERVICE=true
            ;;
        --cron)
            USE_CRON=true
            ;;
        --auto-update)
            USE_AUTO_UPDATE=true
            ;;
        --interval=*)
            CRON_INTERVAL="${arg#*=}"
            USE_CRON=true
            ;;
        --redundant)
            USE_SERVICE=true
            USE_CRON=true
            ;;
        --help|-h)
            SHOW_HELP=true
            ;;
        *)
            echo "Warning: Unknown option $arg"
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    cat << 'EOF'
Simple Daemon Installation

Options:
  --service       Setup systemd service
  --cron          Setup cron job
  --interval=N    Cron interval in minutes (default: 5)
  --redundant     Both service and cron (recommended)
  --auto-update   Enable weekly auto-updates
  --help          Show this help

Examples:
  ./install.sh --redundant --auto-update
  ./install.sh --service --interval=10
  ./install.sh --cron --auto-update

EOF
    exit 0
fi

# Build installation arguments
INSTALL_ARGS=""
[ "$USE_SERVICE" = true ] && INSTALL_ARGS="$INSTALL_ARGS --service"
[ "$USE_CRON" = true ] && INSTALL_ARGS="$INSTALL_ARGS --cron --interval=$CRON_INTERVAL"
[ "$USE_AUTO_UPDATE" = true ] && INSTALL_ARGS="$INSTALL_ARGS --auto-update"

# Default to redundant automation if nothing specified
if [ "$USE_SERVICE" = false ] && [ "$USE_CRON" = false ]; then
    INSTALL_ARGS="--redundant"
fi

# Run installation
stacker_log "Starting installation with options:$INSTALL_ARGS"
stacker_install $INSTALL_ARGS

# Show completion message
echo ""
echo "=================================================="
echo "  Simple Daemon Installation Complete!"
echo "=================================================="
echo ""
echo "Commands:"
echo "  simple-daemon status    # Show daemon status"
echo "  simple-daemon start     # Start daemon manually"
echo "  simple-daemon stop      # Stop daemon manually"
echo ""

# Show service status
stacker_status