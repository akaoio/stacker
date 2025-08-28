# {{project.name}} API Reference

{{project.description}}

## Core API

### Framework Functions

#### `stacker_init()`
Initialize the Stacker framework.

**Usage**: `stacker_init [options]`

**Returns**: 0 on success, 1 on failure

**Example**:
```bash
stacker_init || exit 1
```

---

#### `stacker_load_module()`
Load a Stacker module dynamically.

**Usage**: `stacker_load_module module_name`

**Parameters**:
- `module_name`: Name of the module to load

**Returns**: 0 on success, 1 on failure

**Example**:
```bash
stacker_load_module "config" || {
    echo "Failed to load config module"
    exit 1
}
```

---

#### `stacker_config_get()`
Get a configuration value.

**Usage**: `stacker_config_get key [default]`

**Parameters**:
- `key`: Configuration key
- `default`: Optional default value

**Returns**: Configuration value or default

**Example**:
```bash
interval=$(stacker_config_get "update.interval" "3600")
```

---

#### `stacker_config_set()`
Set a configuration value.

**Usage**: `stacker_config_set key value`

**Parameters**:
- `key`: Configuration key
- `value`: Configuration value

**Returns**: 0 on success, 1 on failure

**Example**:
```bash
stacker_config_set "update.interval" "1800"
```

---

#### `stacker_log()`
Log a message with level.

**Usage**: `stacker_log level message`

**Parameters**:
- `level`: Log level (debug, info, warn, error)
- `message`: Message to log

**Example**:
```bash
stacker_log "info" "Starting update process"
stacker_log "error" "Failed to connect to server"
```

---

#### `stacker_error()`
Handle errors with proper cleanup.

**Usage**: `stacker_error message [exit_code]`

**Parameters**:
- `message`: Error message
- `exit_code`: Optional exit code (default: 1)

**Example**:
```bash
command || stacker_error "Command failed" 2
```

---

### Service Functions

#### `stacker_service_start()`
Start a Manager service.

**Usage**: `stacker_service_start [service_name]`

**Returns**: 0 on success, 1 on failure

---

#### `stacker_service_stop()`
Stop a Manager service.

**Usage**: `stacker_service_stop [service_name]`

**Returns**: 0 on success, 1 on failure

---

#### `stacker_service_status()`
Get service status.

**Usage**: `stacker_service_status [service_name]`

**Returns**: Service status string

---

### Installation Functions

#### `stacker_install()`
Install a Manager-based application.

**Usage**: `stacker_install [options]`

**Options**:
- `--systemd`: Install as systemd service
- `--cron`: Install as cron job
- `--prefix`: Installation prefix

**Returns**: 0 on success, 1 on failure

---

#### `stacker_uninstall()`
Uninstall a Manager-based application.

**Usage**: `stacker_uninstall [options]`

**Returns**: 0 on success, 1 on failure

---

### Update Functions

#### `stacker_update_check()`
Check for available updates.

**Usage**: `stacker_update_check`

**Returns**: 0 if update available, 1 if current

---

#### `stacker_update_apply()`
Apply available updates.

**Usage**: `stacker_update_apply [version]`

**Parameters**:
- `version`: Optional specific version

**Returns**: 0 on success, 1 on failure

---

#### `stacker_rollback()`
Rollback to previous version.

**Usage**: `stacker_rollback [version]`

**Returns**: 0 on success, 1 on failure

---

## Module API

### Creating a Module

Modules must export these variables:

```bash
STACKER_MODULE_NAME="module-name"
STACKER_MODULE_VERSION="1.0.0"
STACKER_MODULE_DESCRIPTION="Module description"
```

### Module Lifecycle

#### `module_init()`
Called when module is loaded.

**Required**: Yes

**Example**:
```bash
module_init() {
    # Initialize module state
    MODULE_STATE="initialized"
    return 0
}
```

---

#### `module_cleanup()`
Called when module is unloaded.

**Required**: No

**Example**:
```bash
module_cleanup() {
    # Clean up resources
    unset MODULE_STATE
    return 0
}
```

---

#### `module_verify()`
Verify module integrity.

**Required**: No

**Example**:
```bash
module_verify() {
    # Check module dependencies
    command -v required_command >/dev/null 2>&1 || return 1
    return 0
}
```

---

## Environment Variables

### Core Variables

{{#each environment_variables}}
#### {{this.name}}
{{this.description}}

**Default**: `{{this.default}}`

{{/each}}

### Module Variables

Modules can access these variables:

- `STACKER_MODULE_PATH`: Module search path
- `STACKER_MODULE_CACHE`: Module cache directory
- `STACKER_MODULE_REGISTRY`: Module registry file

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Module loading error |
| 4 | Service error |
| 5 | Installation error |
| 6 | Update error |
| 10 | Permission denied |
| 11 | Resource not found |
| 12 | Invalid argument |

## Shell Compatibility

Stacker is tested with:

- `/bin/sh` (POSIX shell)
- `dash` (Debian Almquist shell)
- `ash` (Almquist shell)
- `bash` (Bourne Again shell)
- `zsh` (Z shell)

## Examples

### Basic Usage

```bash
#!/bin/sh
# Load Stacker framework
. /usr/local/lib/stacker/stacker-core.sh

# Initialize
stacker_init || exit 1

# Use framework functions
stacker_log "info" "Application starting"
config_value=$(stacker_config_get "app.setting" "default")
```

### Creating a Service

```bash
#!/bin/sh
# My Service using Manager

# Load Manager
. /usr/local/lib/stacker/stacker-core.sh
stacker_init || exit 1

# Service logic
service_run() {
    while true; do
        stacker_log "info" "Service running"
        # Do work here
        sleep 60
    done
}

# Start service
stacker_service_start "my-service"
service_run
```

### Module Development

```bash
#!/bin/sh
# Custom Stacker module

# Module metadata
STACKER_MODULE_NAME="custom"
STACKER_MODULE_VERSION="1.0.0"
STACKER_MODULE_DESCRIPTION="Custom module"

# Module initialization
module_init() {
    stacker_log "debug" "Custom module initialized"
    return 0
}

# Module functions
custom_function() {
    echo "Custom functionality"
}

# Module cleanup
module_cleanup() {
    stacker_log "debug" "Custom module cleaned up"
    return 0
}
```

---

*{{project.name}} API Reference*

*Version {{project.version}} | License: {{project.license}}*