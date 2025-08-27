# @akaoio/manager

**Universal POSIX Shell Framework for System Management**

A powerful, reusable shell framework that provides standardized patterns for installation, updates, services, and configuration management across any POSIX-compliant system. Now with enhanced project-specific configuration support.

## 🚀 Features

### Core Capabilities
✅ **Universal Project Support** - Works with shell scripts, Node.js apps, and any executable  
✅ **Project Configuration System** - Flexible `.manager-config` for project-specific needs  
✅ **XDG Base Directory Compliance** - Proper file organization following standards  
✅ **Clean Clone Architecture** - Git-based source management with isolation  
✅ **Automatic Privilege Detection** - Smart sudo/non-sudo handling  
✅ **Color-Aware Output** - Respects `NO_COLOR` and `FORCE_COLOR` standards  

### Installation Management
- Multi-method installation (system-wide, user-local, custom paths)
- Automatic dependency checking and installation
- Legacy file cleanup during updates
- Additional files and directories support
- Project-specific configuration via `.manager-config`

### Service Management  
- Systemd service creation (system and user level)
- Cron job setup with flexible intervals
- Redundant automation (service + cron for reliability)
- Health monitoring and auto-restart capabilities
- Service status and log management

### Update System
- Git-based auto-updates from repositories
- Rollback capability on update failures
- Scheduled weekly auto-updates
- Clean clone maintenance
- Version tracking and logging

### Configuration Management
- JSON-based configuration with validation
- Environment variable overrides
- Secure credential storage (600 permissions)
- XDG-compliant paths
- Backup and restore functionality

## 📦 Installation

### For Your Project

1. **Add Manager as a dependency** (recommended):
```bash
git submodule add https://github.com/akaoio/manager.git manager
```

2. **Or clone directly**:
```bash
git clone https://github.com/akaoio/manager.git
```

3. **Source in your installer**:
```bash
#!/bin/sh
# Your project's install.sh

# Load Manager framework
. ./manager/manager.sh

# Initialize Manager for your project
manager_init "your-app" \
             "https://github.com/yourorg/yourapp.git" \
             "yourapp.sh" \
             "Your Application Description"

# Use Manager functions
manager_install --service --cron --auto-update
```

## 🔧 Project Configuration

Create a `.manager-config` file in your project root to customize Manager's behavior:

```bash
# .manager-config - Project-specific Manager configuration

# Additional files to install (space-separated)
ADDITIONAL_FILES="helper.sh utils.sh config.json"

# Legacy files to remove during updates (space-separated)
LEGACY_FILES="old-script.sh deprecated.conf"

# Directories to install (space-separated)
DIRECTORIES="templates providers modules"

# Node.js specific (if applicable)
NODE_ENTRY_POINT="server.js"  # Default: main.js or package.json's main

# Custom installation hooks (optional)
BEFORE_INSTALL_HOOK="setup_database"
AFTER_INSTALL_HOOK="initialize_config"

# Service configuration
SERVICE_TYPE="forking"  # simple (default), forking, oneshot
SERVICE_RESTART="always"  # always (default), on-failure, no

# Update behavior
AUTO_UPDATE_ENABLED="true"  # Enable weekly auto-updates
UPDATE_CHANNEL="stable"  # stable (default), beta, dev
```

## 📚 API Reference

### Core Functions

#### `manager_init`
Initialize Manager for your project:
```bash
manager_init "app-name" "git-url" "main-script" "description"
```

#### `manager_install`
Install your application with options:
```bash
# Basic installation
manager_install

# With automation
manager_install --service --cron --auto-update

# Custom paths
manager_install --prefix=/opt/myapp --interval=10
```

#### `manager_uninstall`
Remove your application completely:
```bash
manager_uninstall "app-name"
```

#### `manager_update`
Update to latest version:
```bash
manager_update "app-name"
```

### Service Management

#### `manager_service_create`
Create systemd service:
```bash
manager_service_create "app-name" "Description" "/usr/local/bin/app"
```

#### `manager_service_start/stop/restart`
Control services:
```bash
manager_service_start "app-name"
manager_service_stop "app-name"
manager_service_restart "app-name"
```

#### `manager_cron_setup`
Setup cron job:
```bash
manager_cron_setup "app-name" 5  # Run every 5 minutes
```

### Configuration Management

#### `manager_config_set/get`
Manage configuration:
```bash
manager_config_set "key" "value"
value=$(manager_config_get "key")
```

#### `manager_save_config/load_config`
Save and load full configuration:
```bash
manager_save_config
manager_load_config
```

### Utility Functions

#### `manager_log/info/warn/error`
Logging with colors and file output:
```bash
manager_log "Installation starting..."
manager_info "Using configuration from ~/.config/app"
manager_warn "Old version detected, will upgrade"
manager_error "Installation failed"
```

#### `manager_check_command`
Check if command exists:
```bash
if manager_check_command "git"; then
    manager_log "Git is available"
fi
```

#### `manager_exec_privileged`
Execute with appropriate privileges:
```bash
manager_exec_privileged "/usr/local/bin" cp file.sh /usr/local/bin/
```

## 🎯 Usage Examples

### Simple Shell Script
```bash
#!/bin/sh
# install.sh for a shell script project

. ./manager/manager.sh

manager_init "backup-tool" \
             "https://github.com/example/backup-tool.git" \
             "backup.sh" \
             "Automated backup utility"

# Interactive installation
if [ $# -eq 0 ]; then
    echo "How would you like to run backup-tool?"
    echo "1) Systemd service"
    echo "2) Cron job"
    echo "3) Manual only"
    read -r choice
    
    case $choice in
        1) manager_install --service ;;
        2) manager_install --cron --interval=60 ;;
        3) manager_install ;;
    esac
else
    manager_install "$@"
fi
```

### Node.js Application
```bash
#!/bin/sh
# install.sh for Node.js app

. ./manager/manager.sh

# Create .manager-config for Node.js
cat > .manager-config << 'EOF'
NODE_ENTRY_POINT="server.js"
ADDITIONAL_FILES="ecosystem.config.js"
SERVICE_TYPE="simple"
SERVICE_RESTART="always"
EOF

manager_init "web-server" \
             "https://github.com/example/web-server.git" \
             "web-server" \
             "Production web server"

manager_install --service --auto-update
```

### Multi-Component System
```bash
#!/bin/sh
# install.sh for complex system

. ./manager/manager.sh

# Configure Manager for complex setup
cat > .manager-config << 'EOF'
ADDITIONAL_FILES="config.yaml ssl/cert.pem ssl/key.pem"
DIRECTORIES="plugins templates data"
LEGACY_FILES="old-config.ini deprecated-plugin.sh"
BEFORE_INSTALL_HOOK="prepare_environment"
AFTER_INSTALL_HOOK="initialize_database"
EOF

# Define hooks
prepare_environment() {
    manager_log "Preparing environment..."
    mkdir -p /var/lib/myapp
    chmod 750 /var/lib/myapp
}

initialize_database() {
    manager_log "Initializing database..."
    sqlite3 /var/lib/myapp/data.db < schema.sql
}

manager_init "complex-app" \
             "https://github.com/example/complex-app.git" \
             "main.sh" \
             "Complex application system"

# Full installation with redundancy
manager_install --service --cron --auto-update --redundant
```

## 🔒 Security Features

- **No hardcoded credentials** - All secrets in environment or config files
- **File permission enforcement** - Config files set to 600, scripts to 755
- **Privilege separation** - Runs with minimum required privileges
- **XDG compliance** - Proper separation of config, data, and cache
- **Secure updates** - Git-based with signature verification support
- **Input validation** - All user inputs sanitized and validated

## 🧪 Testing

Manager includes comprehensive tests:

```bash
# Run POSIX compliance tests
./tests/test-posix-compliance.sh

# Test installation flow
./tests/test-install.sh

# Test service management
./tests/test-services.sh

# Run all tests
./tests/run-all-tests.sh
```

## 🤝 Contributing

Contributions are welcome! Please ensure:
1. **POSIX compliance** - No bashisms or GNU-specific features
2. **XDG compliance** - Follow Base Directory Specification
3. **Documentation** - Update docs for new features
4. **Testing** - Add tests for new functionality
5. **Compatibility** - Test on multiple shells (sh, dash, bash, zsh)

## 📋 Requirements

- POSIX-compliant shell (`/bin/sh`)
- Standard utilities: `grep`, `sed`, `awk`, `cut`
- Git (for updates and clean clone)
- Optional: `systemd`, `cron`, `sudo`

## 🔄 Compatibility

Tested and working on:
- **Linux**: Ubuntu, Debian, Fedora, CentOS, RHEL, Alpine, Arch
- **macOS**: 10.15+ (Catalina and later)
- **BSD**: FreeBSD, OpenBSD, NetBSD
- **Shells**: sh, dash, bash, zsh, ksh
- **Init Systems**: systemd, OpenRC, SysV, launchd

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🌟 Projects Using Manager

- [@akaoio/access](https://github.com/akaoio/access) - DNS synchronization
- [@akaoio/air](https://github.com/akaoio/air) - P2P database
- [@akaoio/composer](https://github.com/akaoio/composer) - Documentation engine
- [@akaoio/battle](https://github.com/akaoio/battle) - Terminal testing framework

## 📚 Additional Documentation

- [POSIX-XDG-COMPLIANCE.md](POSIX-XDG-COMPLIANCE.md) - Standards compliance details
- [examples/](examples/) - Complete example implementations
- [tests/](tests/) - Test suite and examples

## 💡 Philosophy

> "While languages come and go, shell is eternal."

Manager embodies the Unix philosophy:
- Do one thing well (system management)
- Make it universal (POSIX compliance)
- Keep it simple (pure shell)
- Make it composable (reusable framework)

---

**Built with ❤️ for the POSIX-compliant world**