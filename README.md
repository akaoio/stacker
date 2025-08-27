# @akaoio/manager

**Universal Shell Framework for POSIX-compliant System Management**

A reusable shell framework that provides standardized patterns for installer, updater, uninstaller, status, service, and cron management across all AKAO technologies.

## Philosophy

- **Pure POSIX Shell** - Works on any Unix-like system forever
- **Zero Dependencies** - Only standard POSIX utilities required
- **XDG Compliance** - Follows Base Directory Specification  
- **Universal Patterns** - Consistent behavior across all technologies
- **Sudo/Non-sudo Support** - Automatic privilege detection and fallback

## Features

✅ **Installation Management**
- Clean clone architecture 
- XDG-compliant directory structure
- Automatic requirements checking
- Multi-package manager support

✅ **Service Management**  
- Systemd service creation (system + user)
- Cron job setup and management
- Redundant automation (service + cron backup)
- Health monitoring and auto-restart

✅ **Update System**
- Git-based auto-update from repositories
- Rollback capability on failures
- Scheduled weekly updates
- Clean clone maintenance

✅ **Configuration**
- JSON-based configuration with environment overrides
- Secure credential storage
- Input validation and sanitization
- XDG Base Directory compliance

✅ **Cross-Platform Support**
- Auto-detection of OS and package manager
- Ubuntu/Debian, RHEL/CentOS/Fedora, Alpine Linux, macOS
- Both sudo and non-sudo environments
- Systemd and non-systemd systems

## Quick Start

```bash
# Include manager framework in your installer
#!/bin/sh
MANAGER_DIR="$(dirname "$0")/manager"
. "$MANAGER_DIR/manager.sh"

# Configure your technology
manager_init "mytool" "https://github.com/user/mytool.git" "mytool.sh"
manager_install
manager_setup_service
```

## Architecture

The framework provides modular shell libraries:

- `manager.sh` - Main entry point and orchestration
- `manager-core.sh` - Core utilities and logging  
- `manager-install.sh` - Installation workflows
- `manager-service.sh` - Service management
- `manager-update.sh` - Auto-update systems
- `manager-config.sh` - Configuration handling

## Examples

See `examples/` directory for complete implementations:

- `simple-daemon/` - Basic background service
- `web-app/` - Web application with HTTP health checks
- `cli-tool/` - Command-line utility installation

## Integration with AKAO Technologies

This framework standardizes installation and management across:

- **@akaoio/access** - Dynamic DNS synchronization
- **@akaoio/air** - P2P database system  
- **@akaoio/composer** - Documentation engine
- **@akaoio/battle** - Testing framework
- **@akaoio/builder** - Build system

## Development

```bash
# Test framework components
./tests/run-all-tests.sh

# Test with different shells
./tests/test-posix-compliance.sh

# Validate XDG compliance
./tests/test-xdg-compliance.sh
```

## Why Manager?

Every AKAO technology was implementing the same shell patterns:
- XDG directory creation
- Service setup (systemd + cron)  
- Clean clone architecture
- Auto-update mechanisms
- Requirements checking

Manager extracts these patterns into a reusable framework, ensuring consistency and reducing maintenance overhead across the entire ecosystem.

**One framework. Universal patterns. Eternal compatibility.**

---

*Part of the AKAO ecosystem - Building the future of development tooling*