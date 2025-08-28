# CLAUDE.md - @akaoio/manager

This file provides guidance to Claude Code (claude.ai/code) when working with the @akaoio/manager codebase.

## Project Overview

**@akaoio/manager** - Universal POSIX shell framework for system management - The foundational framework that standardizes patterns across all technologies with modular architecture

**Version**: 2.0.0  
**License**: MIT  
**Author**: AKAO.IO  
**Repository**: https://github.com/akaoio/manager  
**Philosophy**: "Manager brings order to chaos - a universal shell framework with modular loading that works everywhere, forever."

## Core Development Principles


### Universal POSIX Compliance
Pure POSIX shell implementation that runs on any Unix-like system without dependencies



### Framework Pattern Standardization
Establishes universal patterns for shell-based system management across all environments



### Zero Dependencies
No external dependencies, no runtimes, no package managers - just pure shell



### Eternal Infrastructure
Built to last forever - when languages come and go, Manager remains




## Architecture Overview

### System Design

Manager is a comprehensive shell framework that provides standardized patterns for system management, configuration, installation, updates, and service orchestration.

### Core Components


**Core Module (manager-core.sh)**
- Central framework providing common functions, error handling, logging, and state management
- Responsibility: Foundation layer for all Manager operations


**Configuration Module (manager-config.sh)**
- XDG-compliant configuration management with JSON support and environment variable overrides
- Responsibility: Centralized configuration handling across all modules


**Installation Module (manager-install.sh)**
- Universal installation framework supporting systemd, cron, and manual deployment
- Responsibility: Standardized installation across different environments


**Update Module (manager-update.sh)**
- Intelligent update system with version management and rollback capabilities
- Responsibility: Safe and reliable system updates


**Service Module (manager-service.sh)**
- Service lifecycle management for systemd, init.d, and standalone daemons
- Responsibility: Unified service control interface


**CLI Module (manager-cli.sh)**
- Command-line interface with subcommand routing and argument parsing
- Responsibility: User interaction and command processing


**Self-Update Module (manager-self-update.sh)**
- Auto-update capability with integrity verification and atomic updates
- Responsibility: Framework self-maintenance



## Features


### Universal Shell Patterns
Standardized patterns for error handling, logging, configuration, and state management


### Dynamic Module Loading
On-demand module loading with automatic dependency resolution and smart caching


### Modular Architecture
Clean separation of concerns with independent, reusable modules that load only when needed


### Module Registry System
Comprehensive module tracking, dependency management, and initialization lifecycle


### Auto-Loading Intelligence
Smart function detection that automatically loads required modules based on function calls


### XDG Compliance
Full XDG Base Directory specification compliance for configuration and data storage


### Multi-Platform Support
Works on Linux, BSD, macOS, and any POSIX-compliant system


### Service Integration
Native integration with systemd, init.d, launchd, and cron


### Atomic Operations
Safe atomic updates and rollback capabilities for critical operations


### Version Management
Semantic versioning with compatibility checking and migration support


### Health Monitoring
Built-in health checks and diagnostic capabilities



## Command Interface

### Core Commands

```bash

manager init [--template=TYPE]  # Initialize Manager framework in current directory

manager config [get|set|list] [key] [value]  # Manage configuration settings

manager install [--systemd|--cron|--manual] [options]  # Install Manager-based application

manager update [--check|--force]  # Update Manager-based application

manager service [start|stop|restart|status|enable|disable]  # Control Manager service

manager health [--verbose]  # Check system health and diagnostics

manager rollback [version]  # Rollback to previous version

manager self-update [--check]  # Update Manager framework itself

manager version [--json]  # Show version information

manager help [command]  # Show help information

```

### Detailed Command Reference


#### `init` Command
**Purpose**: Initialize Manager framework in current directory  
**Usage**: `manager init [--template=TYPE]`



#### `config` Command
**Purpose**: Manage configuration settings  
**Usage**: `manager config [get|set|list] [key] [value]`



#### `install` Command
**Purpose**: Install Manager-based application  
**Usage**: `manager install [--systemd|--cron|--manual] [options]`



#### `update` Command
**Purpose**: Update Manager-based application  
**Usage**: `manager update [--check|--force]`



#### `service` Command
**Purpose**: Control Manager service  
**Usage**: `manager service [start|stop|restart|status|enable|disable]`



#### `health` Command
**Purpose**: Check system health and diagnostics  
**Usage**: `manager health [--verbose]`



#### `rollback` Command
**Purpose**: Rollback to previous version  
**Usage**: `manager rollback [version]`



#### `self-update` Command
**Purpose**: Update Manager framework itself  
**Usage**: `manager self-update [--check]`



#### `version` Command
**Purpose**: Show version information  
**Usage**: `manager version [--json]`



#### `help` Command
**Purpose**: Show help information  
**Usage**: `manager help [command]`









## Environment Variables


### MANAGER_CONFIG_DIR
- **Description**: Override default config directory
- **Default**: `$HOME/.config/manager`


### MANAGER_DATA_DIR
- **Description**: Override default data directory
- **Default**: `$HOME/.local/share/manager`


### MANAGER_LOG_LEVEL
- **Description**: Logging level (debug, info, warn, error)
- **Default**: `info`


### MANAGER_UPDATE_CHANNEL
- **Description**: Update channel (stable, beta, nightly)
- **Default**: `stable`


### MANAGER_AUTO_UPDATE
- **Description**: Enable automatic updates
- **Default**: `false`


### MANAGER_PREFIX
- **Description**: Installation prefix
- **Default**: `/usr/local`



## Development Guidelines

### Shell Script Standards

**POSIX Compliance**
- Use `/bin/sh` (not bash-specific features)
- Avoid bashisms and GNU-specific extensions
- Test on multiple shells (dash, ash, bash)

**Error Handling**
- Always check exit codes: `command || handle_error`
- Use proper error messages with context
- Fail fast and clearly on configuration errors

**Security Practices**
- Validate all user input
- Use secure temp file creation
- Never expose sensitive data in logs
- Proper file permissions (600 for configs)

### Code Organization

```
manager.sh              # Main entry point
├── Core Functions
│   ├── manager_init()      # Framework initialization
│   ├── manager_config()    # Configuration management
│   └── manager_error()     # Error handling
├── Module Loading
│   ├── load_module()       # Dynamic module loading
│   └── verify_module()     # Module verification
└── Utility Functions
    ├── log()              # Logging functionality
    ├── validate_posix()   # POSIX compliance check
    └── check_deps()       # Dependency verification
```

### Module Development

Each module follows this pattern:

```bash
#!/bin/sh
# Module: module-name
# Description: Brief description
# Dependencies: none (or list them)

# Module initialization
module_init() {
    # Initialization code
}

# Module functions
module_function() {
    # Function implementation
}

# Module cleanup
module_cleanup() {
    # Cleanup code
}

# Export module interface
MANAGER_MODULE_NAME="module-name"
MANAGER_MODULE_VERSION="1.0.0"
```

### Testing Requirements

**Manual Testing**
- Test on multiple shells (sh, dash, ash, bash)
- Verify on different Unix-like systems
- Test failure scenarios and recovery
- Validate all command options

**Test Framework**
```bash
# Run all tests
./tests/run-all.sh

# Run specific test
./tests/test-core.sh

# Test with specific shell
SHELL=/bin/dash ./tests/run-all.sh
```

## Common Patterns

### Standard Error Handling
```bash
# Function with error handling
function_name() {
    command || {
        log "ERROR: Command failed: $*"
        return 1
    }
}
```

### Configuration Validation
```bash
# Validate required configuration
validate_config() {
    [ -z "$CONFIG_VALUE" ] && {
        echo "ERROR: CONFIG_VALUE not set"
        exit 1
    }
}
```

### Safe Temp File Creation
```bash
# Create temporary file safely
TEMP_FILE=$(mktemp) || exit 1
trap 'rm -f "$TEMP_FILE"' EXIT
```

### Module Loading
```bash
# Load module with verification
load_module "module-name" || {
    log "ERROR: Failed to load module: module-name"
    exit 1
}
```

## Use Cases


### 0. System initialization and bootstrapping

### 1. Application deployment and management

### 2. Service orchestration and monitoring

### 3. Configuration management across environments

### 4. Automated updates and maintenance

### 5. Cross-platform shell script development

### 6. Infrastructure automation without dependencies

### 7. Emergency recovery systems


## Security Considerations

### Framework Security
- All modules verified before loading
- Configuration files with restricted permissions (600)
- No execution of untrusted code
- Input validation at all entry points

### Deployment Security
- Secure installation process
- Proper service user creation
- Limited privileges for service execution
- Audit logging for critical operations

## Troubleshooting Guide

### Common Issues

**Module Loading Failures**
```bash
# Debug module loading
MANAGER_DEBUG=true manager init

# Check module path
echo $MANAGER_MODULE_PATH

# Verify module syntax
sh -n module-name.sh
```

**Configuration Issues**
```bash
# Check configuration
manager config list

# Validate configuration file
manager config validate

# Reset configuration
rm -rf ~/.config/manager
manager init
```

**Service Issues**
```bash
# Check service status
manager service status

# View service logs
journalctl -u manager -f

# Restart service
manager service restart
```

## Notes for AI Assistants

When working with Manager:

### Critical Guidelines
- **ALWAYS maintain POSIX compliance** - test with `/bin/sh`
- **NEVER introduce dependencies** - pure shell only
- **Follow the module pattern** - consistency is key
- **Test on multiple shells** - dash, ash, sh, bash
- **Respect the framework philosophy** - universal patterns

### Development Best Practices
- **Start with the core module** - understand the foundation
- **Use existing patterns** - don't reinvent the wheel
- **Test error conditions** - robust error handling
- **Document module interfaces** - clear contracts
- **Validate all inputs** - security first

### Common Mistakes to Avoid
- Using bash-specific features (arrays, [[ ]], etc.)
- Assuming GNU coreutils extensions
- Hardcoding paths instead of using variables
- Forgetting to check exit codes
- Not testing on minimal systems

### Framework Extensions
When extending Manager:
1. Create new module following the pattern
2. Add module to the module registry
3. Update configuration schema if needed
4. Add tests for new functionality
5. Document in module header

## Why Manager Matters

Manager is the foundational framework that brings consistency and reliability to shell-based system management. While modern tools require complex dependencies and runtimes, Manager provides a universal, dependency-free solution that works everywhere, forever.

### Benefits

- No dependencies means no dependency hell

- POSIX compliance ensures universal compatibility

- Standardized patterns reduce complexity and errors

- Framework approach enables rapid development

- Battle-tested reliability for production systems

- Emergency recovery when other systems fail

- Educational resource for shell best practices


---

*Manager is the foundation - bringing order to chaos through universal shell patterns.*

*Version: 2.0.0 | License: MIT | Author: AKAO.IO*