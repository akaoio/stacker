# Simple Daemon Example

This example demonstrates how to use the @akaoio/stacker framework to create a complete installation and management system for a simple daemon application.

## Features Demonstrated

- **Installation**: Complete setup with service management
- **XDG Compliance**: Proper directory structure following standards
- **Service Management**: Both systemd and cron support
- **Auto-Update**: Automated update system with clean clone maintenance
- **Logging**: Structured logging with rotation
- **Uninstallation**: Clean removal with optional data preservation

## Files

- `install.sh` - Installation script using manager framework
- `simple-daemon.sh` - The actual daemon application
- `uninstall.sh` - Clean uninstallation script
- `README.md` - This documentation

## Installation

```bash
# Basic installation with redundant automation
./install.sh --redundant --auto-update

# Systemd service only
./install.sh --service

# Cron job only with custom interval
./install.sh --cron --interval=10

# Show help
./install.sh --help
```

## Usage

After installation, the daemon can be controlled with:

```bash
# Start daemon
simple-daemon start

# Check status  
simple-daemon status

# Stop daemon
simple-daemon stop

# Restart daemon
simple-daemon restart

# Show version
simple-daemon version
```

## Service Management

**Systemd Commands:**
```bash
# User service
systemctl --user start simple-daemon
systemctl --user status simple-daemon
systemctl --user stop simple-daemon

# View logs
journalctl --user -u simple-daemon -f
```

**Cron Management:**
```bash
# View cron jobs
crontab -l

# Remove cron job
crontab -l | grep -v simple-daemon | crontab -
```

## File Locations

Following XDG Base Directory Specification:

- **Config**: `~/.config/simple-daemon/`
  - `config.json` - Main configuration
  - `auto-update.sh` - Update script
  - `auto-update.log` - Update logs
  - `backups/` - Configuration backups

- **Data**: `~/.local/share/simple-daemon/`
  - `daemon.log` - Application logs

- **State**: `~/.local/state/simple-daemon/`
  - `daemon.pid` - Process ID file

- **Clean Clone**: `~/simple-daemon/`
  - Used for updates and runtime

## Framework Integration

This example shows how to integrate with the manager framework:

```bash
# Load framework
STACKER_DIR="$(dirname "$0")/../../"
. "$STACKER_DIR/stacker.sh"

# Initialize for technology
stacker_init "simple-daemon" \
             "https://github.com/example/simple-daemon.git" \
             "simple-daemon.sh" \
             "Example daemon service"

# Install with options
stacker_install --redundant --auto-update
```

## Auto-Update System

When `--auto-update` is enabled:

- Updates check weekly (Sunday 3 AM)
- Maintains clean clone from git repository
- Automatic rollback on failed updates
- Service restart after successful updates
- Update logs in `~/.config/simple-daemon/auto-update.log`

## Uninstallation

```bash
# Complete removal
./uninstall.sh

# Keep configuration
./uninstall.sh --keep-config

# Keep data files
./uninstall.sh --keep-data

# Keep both
./uninstall.sh --keep-config --keep-data
```

## Customization

To adapt this example for your own daemon:

1. **Update install.sh**:
   - Change repository URL
   - Update service description
   - Modify technology name

2. **Update simple-daemon.sh**:
   - Implement your daemon logic
   - Customize configuration options
   - Add your specific commands

3. **Test installation**:
   - Verify all features work
   - Test service management
   - Confirm XDG compliance

## Testing

```bash
# Test installation
./install.sh --redundant --auto-update

# Verify service is running
simple-daemon status
systemctl --user status simple-daemon

# Test update system
~/.config/simple-daemon/auto-update.sh

# Test uninstallation
./uninstall.sh
```

This example provides a complete template for creating professional-grade system services using the manager framework's standardized patterns.