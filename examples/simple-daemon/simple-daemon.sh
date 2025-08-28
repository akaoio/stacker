#!/bin/sh
# Simple daemon script - Example application using manager patterns

# Configuration
DAEMON_NAME="simple-daemon"
DAEMON_VERSION="1.0.0"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/$DAEMON_NAME"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/$DAEMON_NAME"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/$DAEMON_NAME"
PID_FILE="$STATE_DIR/daemon.pid"
LOG_FILE="$DATA_DIR/daemon.log"

# Colors for output
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    NC=''
fi

# Logging functions
log() {
    echo "${GREEN}[$DAEMON_NAME]${NC} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

warn() {
    echo "${YELLOW}[Warning]${NC} $*" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" >> "$LOG_FILE"
}

error() {
    echo "${RED}[Error]${NC} $*" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >> "$LOG_FILE"
}

# Ensure required directories exist
ensure_dirs() {
    mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$STATE_DIR"
}

# Check if daemon is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # Remove stale PID file
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Start daemon
start_daemon() {
    ensure_dirs
    
    if is_running; then
        log "Daemon is already running"
        return 0
    fi
    
    log "Starting $DAEMON_NAME daemon..."
    
    # Start daemon in background
    (
        # Write PID
        echo $$ > "$PID_FILE"
        
        # Main daemon loop
        while true; do
            log "Daemon heartbeat - $(date)"
            
            # Example work: just sleep and log
            sleep 30
            
            # Check for stop signal
            if [ ! -f "$PID_FILE" ]; then
                log "Stop signal received, exiting"
                break
            fi
        done
    ) &
    
    # Wait a moment and check if it started
    sleep 1
    if is_running; then
        log "Daemon started successfully"
        return 0
    else
        error "Failed to start daemon"
        return 1
    fi
}

# Stop daemon
stop_daemon() {
    if ! is_running; then
        log "Daemon is not running"
        return 0
    fi
    
    log "Stopping $DAEMON_NAME daemon..."
    
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    
    if [ -n "$pid" ]; then
        # Send TERM signal
        if kill -TERM "$pid" 2>/dev/null; then
            # Wait for graceful shutdown
            local count=0
            while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null
                warn "Daemon was force-killed"
            else
                log "Daemon stopped gracefully"
            fi
        fi
    fi
    
    # Clean up PID file
    rm -f "$PID_FILE"
    return 0
}

# Show daemon status
show_status() {
    echo "=========================================="
    echo "  $DAEMON_NAME Status"
    echo "=========================================="
    echo ""
    
    if is_running; then
        local pid uptime
        pid=$(cat "$PID_FILE")
        echo "Status: ${GREEN}Running${NC} (PID: $pid)"
        
        # Try to get process uptime (Linux-specific)
        if [ -f "/proc/$pid/stat" ]; then
            local start_time boot_time current_time uptime_seconds
            start_time=$(cut -d' ' -f22 /proc/$pid/stat 2>/dev/null)
            boot_time=$(cut -d' ' -f1 /proc/uptime 2>/dev/null | cut -d'.' -f1)
            current_time=$(date +%s)
            
            if [ -n "$start_time" ] && [ -n "$boot_time" ]; then
                uptime_seconds=$((current_time - boot_time - start_time/100))
                uptime=$(printf "%d days, %02d:%02d:%02d" \
                    $((uptime_seconds/86400)) \
                    $((uptime_seconds%86400/3600)) \
                    $((uptime_seconds%3600/60)) \
                    $((uptime_seconds%60)))
                echo "Uptime: $uptime"
            fi
        fi
    else
        echo "Status: ${RED}Stopped${NC}"
    fi
    
    echo ""
    echo "Configuration:"
    echo "  Config Dir: $CONFIG_DIR"
    echo "  Data Dir:   $DATA_DIR"
    echo "  State Dir:  $STATE_DIR"
    echo "  PID File:   $PID_FILE"
    echo "  Log File:   $LOG_FILE"
    
    # Show recent log entries
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "Recent Log Entries:"
        tail -5 "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
    fi
    
    echo ""
}

# Show version
show_version() {
    echo "$DAEMON_NAME v$DAEMON_VERSION"
    echo "Example daemon using @akaoio/stacker framework"
}

# Show help
show_help() {
    cat << EOF
$DAEMON_NAME - Simple daemon example

Usage: $DAEMON_NAME <command>

Commands:
  start      Start the daemon
  stop       Stop the daemon
  restart    Restart the daemon
  status     Show daemon status
  daemon     Run in daemon mode (used by service)
  version    Show version information
  help       Show this help

Examples:
  $DAEMON_NAME start
  $DAEMON_NAME status
  $DAEMON_NAME stop

EOF
}

# Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        start)
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon
            sleep 2
            start_daemon
            ;;
        status)
            show_status
            ;;
        daemon)
            # Used by systemd service - run in foreground
            ensure_dirs
            log "Starting daemon in foreground mode"
            
            while true; do
                log "Daemon heartbeat - $(date)"
                sleep 30
            done
            ;;
        version)
            show_version
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo "Run '$DAEMON_NAME help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"