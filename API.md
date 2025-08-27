# Manager Framework API Documentation

Complete API reference for the @akaoio/manager universal POSIX shell framework.

## Table of Contents

1. [Core Functions](#core-functions)
2. [Installation Functions](#installation-functions)
3. [Service Management](#service-management)
4. [Configuration Management](#configuration-management)
5. [Update System](#update-system)
6. [Utility Functions](#utility-functions)
7. [Environment Variables](#environment-variables)
8. [Project Configuration](#project-configuration)

## Core Functions

### `manager_init`
Initialize Manager framework for a project.

**Syntax:**
```bash
manager_init "tech_name" "repo_url" "main_script" "description"
```

**Parameters:**
- `tech_name` - Name of your technology/project
- `repo_url` - Git repository URL
- `main_script` - Main executable file name
- `description` - Human-readable description

**Example:**
```bash
manager_init "myapp" \
             "https://github.com/org/myapp.git" \
             "myapp.sh" \
             "My Application - Does amazing things"
```

**Sets Global Variables:**
- `MANAGER_TECH_NAME` - Project name
- `MANAGER_REPO_URL` - Repository URL
- `MANAGER_MAIN_SCRIPT` - Main script name
- `MANAGER_DESCRIPTION` - Description
- `MANAGER_INSTALL_DIR` - Installation directory
- `MANAGER_CLEAN_CLONE_DIR` - Clean clone location

---

## Installation Functions

### `manager_install`
Main installation function with automatic detection and setup.

**Syntax:**
```bash
manager_install [options]
```

**Options:**
- `--service` - Install as systemd service
- `--cron` - Install as cron job
- `--interval=N` - Cron interval in minutes (default: 5)
- `--auto-update` - Enable weekly auto-updates
- `--prefix=PATH` - Custom installation prefix
- `--redundant` - Install both service and cron

**Example:**
```bash
# Basic installation
manager_install

# Service with auto-update
manager_install --service --auto-update

# Cron every 10 minutes
manager_install --cron --interval=10

# Custom location
manager_install --prefix=/opt/myapp
```

### `manager_install_from_clone`
Install from existing clean clone.

**Syntax:**
```bash
manager_install_from_clone
```

**Internal Use:** Usually called by `manager_install`.

### `manager_install_script`
Install a shell script with proper permissions.

**Syntax:**
```bash
manager_install_script "source_file" "dest_file"
```

**Features:**
- Handles `.manager-config` for additional files
- Removes legacy files during updates
- Installs additional directories

### `manager_install_nodejs_app`
Install Node.js application with wrapper script.

**Syntax:**
```bash
manager_install_nodejs_app "source_dir" "dest_file"
```

**Configuration via `.manager-config`:**
```bash
NODE_ENTRY_POINT="server.js"  # Default: main.js
```

---

## Service Management

### `manager_service_create`
Create systemd service (system or user level).

**Syntax:**
```bash
manager_service_create "name" "description" "exec_path" ["type"]
```

**Parameters:**
- `name` - Service name
- `description` - Service description
- `exec_path` - Path to executable
- `type` - Service type (simple/forking/oneshot)

**Example:**
```bash
manager_service_create "myapp" \
                      "My Application Service" \
                      "/usr/local/bin/myapp" \
                      "simple"
```

### `manager_service_start`
Start a systemd service.

**Syntax:**
```bash
manager_service_start "service_name"
```

### `manager_service_stop`
Stop a systemd service.

**Syntax:**
```bash
manager_service_stop "service_name"
```

### `manager_service_restart`
Restart a systemd service.

**Syntax:**
```bash
manager_service_restart "service_name"
```

### `manager_service_status`
Check service status.

**Syntax:**
```bash
manager_service_status "service_name"
```

### `manager_service_uninstall`
Remove systemd service.

**Syntax:**
```bash
manager_service_uninstall "service_name"
```

### `manager_cron_setup`
Setup cron job for periodic execution.

**Syntax:**
```bash
manager_cron_setup "name" "interval" ["command"]
```

**Parameters:**
- `name` - Job identifier
- `interval` - Minutes between runs
- `command` - Command to run (optional, defaults to update command)

**Example:**
```bash
# Run every 5 minutes
manager_cron_setup "myapp" 5

# Custom command every hour
manager_cron_setup "backup" 60 "/usr/local/bin/backup.sh"
```

### `manager_cron_remove`
Remove cron job.

**Syntax:**
```bash
manager_cron_remove "name"
```

---

## Configuration Management

### `manager_config_set`
Set a configuration value.

**Syntax:**
```bash
manager_config_set "key" "value"
```

**Example:**
```bash
manager_config_set "api_key" "secret123"
manager_config_set "interval" "300"
```

### `manager_config_get`
Get a configuration value.

**Syntax:**
```bash
value=$(manager_config_get "key" ["default"])
```

**Example:**
```bash
api_key=$(manager_config_get "api_key")
interval=$(manager_config_get "interval" "300")  # Default: 300
```

### `manager_save_config`
Save current configuration to file.

**Syntax:**
```bash
manager_save_config
```

**Saves to:** `$MANAGER_CONFIG_DIR/$MANAGER_TECH_NAME.json`

### `manager_load_config`
Load configuration from file.

**Syntax:**
```bash
manager_load_config
```

### `manager_backup_config`
Backup configuration with timestamp.

**Syntax:**
```bash
manager_backup_config
```

**Creates:** `config.json.backup.YYYYMMDD-HHMMSS`

---

## Update System

### `manager_update`
Update to latest version from repository.

**Syntax:**
```bash
manager_update "tech_name"
```

**Features:**
- Git-based updates
- Automatic rollback on failure
- Service restart after update
- Version logging

### `manager_self_update`
Update Manager framework itself.

**Syntax:**
```bash
manager_self_update "tech_name" "repo_url"
```

### `manager_check_updates`
Check if updates are available.

**Syntax:**
```bash
if manager_check_updates; then
    echo "Updates available"
fi
```

### `manager_enable_auto_update`
Enable weekly auto-updates via cron.

**Syntax:**
```bash
manager_enable_auto_update
```

### `manager_disable_auto_update`
Disable auto-updates.

**Syntax:**
```bash
manager_disable_auto_update
```

---

## Utility Functions

### Logging Functions

#### `manager_log`
Standard log message with green prefix.

**Syntax:**
```bash
manager_log "Installation starting..."
```

#### `manager_info`
Informational message with blue prefix.

**Syntax:**
```bash
manager_info "Using configuration from ~/.config/app"
```

#### `manager_warn`
Warning message with yellow prefix (to stderr).

**Syntax:**
```bash
manager_warn "Old version detected"
```

#### `manager_error`
Error message with red prefix (to stderr).

**Syntax:**
```bash
manager_error "Installation failed"
```

#### `manager_debug`
Debug message (only if MANAGER_DEBUG=1).

**Syntax:**
```bash
manager_debug "Variable X = $X"
```

### System Functions

#### `manager_check_command`
Check if a command exists.

**Syntax:**
```bash
if manager_check_command "git"; then
    echo "Git is available"
fi
```

#### `manager_check_privileges`
Check if running with root/sudo privileges.

**Syntax:**
```bash
if manager_check_privileges; then
    echo "Running as root"
fi
```

#### `manager_exec_privileged`
Execute command with appropriate privileges.

**Syntax:**
```bash
manager_exec_privileged "target_dir" command [args...]
```

**Example:**
```bash
# Copies file to system directory with sudo if needed
manager_exec_privileged "/usr/local/bin" cp myapp /usr/local/bin/
```

#### `manager_create_temp_file`
Create a secure temporary file.

**Syntax:**
```bash
temp_file=$(manager_create_temp_file "prefix")
# Use temp_file...
rm -f "$temp_file"
```

#### `manager_get_os_type`
Detect operating system type.

**Syntax:**
```bash
os_type=$(manager_get_os_type)
# Returns: linux, macos, bsd, unknown
```

#### `manager_get_init_system`
Detect init system.

**Syntax:**
```bash
init_system=$(manager_get_init_system)
# Returns: systemd, openrc, sysv, launchd, unknown
```

---

## Environment Variables

### Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MANAGER_DEBUG` | Enable debug output | 0 |
| `MANAGER_VERBOSE` | Enable verbose output | 0 |
| `MANAGER_PREFIX` | Installation prefix | /usr/local |
| `NO_COLOR` | Disable colored output | 0 |
| `FORCE_COLOR` | Force colored output | 0 |

### XDG Base Directory Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `XDG_CONFIG_HOME` | Configuration directory | ~/.config |
| `XDG_DATA_HOME` | Data directory | ~/.local/share |
| `XDG_STATE_HOME` | State directory | ~/.local/state |
| `XDG_CACHE_HOME` | Cache directory | ~/.cache |

### Runtime Variables (Set by manager_init)

| Variable | Description |
|----------|-------------|
| `MANAGER_TECH_NAME` | Technology/project name |
| `MANAGER_REPO_URL` | Git repository URL |
| `MANAGER_MAIN_SCRIPT` | Main executable name |
| `MANAGER_DESCRIPTION` | Project description |
| `MANAGER_INSTALL_DIR` | Installation directory |
| `MANAGER_CLEAN_CLONE_DIR` | Clean clone location |
| `MANAGER_CONFIG_DIR` | Configuration directory |
| `MANAGER_DATA_DIR` | Data directory |
| `MANAGER_LOG_FILE` | Log file path |

---

## Project Configuration

Create `.manager-config` file in project root for customization.

### Configuration Options

```bash
# .manager-config

# Files to install (space-separated)
ADDITIONAL_FILES="helper.sh utils.sh config.json"

# Legacy files to remove (space-separated)
LEGACY_FILES="old-script.sh deprecated.conf"

# Directories to install (space-separated)
DIRECTORIES="templates providers modules"

# Node.js entry point
NODE_ENTRY_POINT="server.js"

# Installation hooks
BEFORE_INSTALL_HOOK="setup_function"
AFTER_INSTALL_HOOK="cleanup_function"

# Service configuration
SERVICE_TYPE="simple"       # simple, forking, oneshot
SERVICE_RESTART="always"    # always, on-failure, no
SERVICE_USER=""            # Empty for current user
SERVICE_GROUP=""           # Empty for current group

# Update configuration
AUTO_UPDATE_ENABLED="true"
UPDATE_CHANNEL="stable"    # stable, beta, dev

# Custom paths
CUSTOM_CONFIG_DIR=""       # Override config directory
CUSTOM_DATA_DIR=""         # Override data directory
CUSTOM_LOG_FILE=""         # Override log file
```

### Hook Functions

Define functions in your install script:

```bash
#!/bin/sh

. ./manager/manager.sh

# Define hook functions
setup_database() {
    manager_log "Setting up database..."
    sqlite3 /var/lib/myapp/data.db < schema.sql
}

initialize_config() {
    manager_log "Creating default configuration..."
    cp config.template.json "$MANAGER_CONFIG_DIR/config.json"
}

# Set hooks in config
cat > .manager-config << EOF
BEFORE_INSTALL_HOOK="setup_database"
AFTER_INSTALL_HOOK="initialize_config"
EOF

# Hooks will be called during installation
manager_init "myapp" "..." "..." "..."
manager_install
```

### Advanced Configuration

```bash
# Complex project configuration
cat > .manager-config << 'EOF'
# Multiple file types
ADDITIONAL_FILES="main.sh lib/*.sh config/*.json docs/*.md"

# Cleanup old versions
LEGACY_FILES="v1/*.sh old-config.ini .deprecated/*"

# Install complete directory structures
DIRECTORIES="plugins templates data ssl"

# Service configuration for daemon
SERVICE_TYPE="forking"
SERVICE_RESTART="on-failure"
SERVICE_RESTART_SEC="10"
SERVICE_ENVIRONMENT="NODE_ENV=production"

# Conditional features
if [ -f "/usr/bin/npm" ]; then
    NODE_ENTRY_POINT="dist/server.js"
fi

# Dynamic configuration
if [ "$(uname)" = "Darwin" ]; then
    CUSTOM_CONFIG_DIR="$HOME/Library/Application Support/myapp"
fi
EOF
```

---

## Error Handling

All Manager functions return:
- `0` - Success
- `1` - Failure

Example error handling:

```bash
#!/bin/sh
set -e  # Exit on error

. ./manager/manager.sh

# Initialize with error checking
manager_init "myapp" "$REPO" "main.sh" "Description" || {
    manager_error "Failed to initialize Manager"
    exit 1
}

# Install with error handling
if ! manager_install --service; then
    manager_error "Installation failed"
    manager_log "Rolling back changes..."
    manager_uninstall "myapp"
    exit 1
fi

manager_log "Installation successful"
```

---

## Best Practices

1. **Always use manager_init first** - Sets up required variables
2. **Check command availability** - Use `manager_check_command`
3. **Use logging functions** - Better than echo for consistency
4. **Handle errors gracefully** - Check return codes
5. **Use .manager-config** - For project-specific settings
6. **Test on multiple systems** - POSIX compliance matters
7. **Document dependencies** - In your README
8. **Use XDG paths** - Via Manager's variables
9. **Implement hooks** - For complex setups
10. **Enable debug mode** - `MANAGER_DEBUG=1` for troubleshooting

---

**Version:** 1.0.0  
**License:** MIT  
**Repository:** https://github.com/akaoio/manager