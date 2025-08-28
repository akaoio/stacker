# CLAUDE.md - @akaoio/stacker

This file provides guidance to Claude Code (claude.ai/code) when working with the @akaoio/stacker codebase.

## Project Overview

**@akaoio/stacker** - Universal POSIX shell framework for system management - The foundational framework that standardizes patterns across all technologies with modular architecture

**Version**: 2.0.0  
**License**: MIT  
**Author**: AKAO.IO  
**Repository**: https://github.com/akaoio/stacker  
**Philosophy**: "Stacker brings order to chaos - a universal shell framework with modular loading that works everywhere, forever."

## Core Development Principles

### Universal POSIX Compliance
Pure POSIX shell implementation that runs on any Unix-like system without dependencies
**Critical**: true

### Framework Pattern Standardization
Establishes universal patterns for shell-based system management across all environments
**Critical**: true

### Zero Dependencies
No external dependencies, no runtimes, no package stackers - just pure shell
**Critical**: true

### Eternal Infrastructure
Built to last forever - when languages come and go, Stacker remains
**Critical**: true


## Architecture Overview

### System Design

Stacker is a comprehensive shell framework that provides standardized patterns for system management, configuration, installation, updates, and service orchestration. Version 2.0.0 features a complete CLI interface with interactive commands and comprehensive help system.

### Core Components

**Core Module (stacker-core.sh)**
- Central framework providing common functions, error handling, logging, and state management
- Responsibility: Foundation layer for all Stacker operations

**Configuration Module (stacker-config.sh)**
- XDG-compliant configuration management with JSON support and environment variable overrides
- Responsibility: Centralized configuration handling across all modules

**Installation Module (stacker-install.sh)**
- Universal installation framework supporting systemd, cron, and manual deployment
- Responsibility: Standardized installation across different environments

**Update Module (stacker-update.sh)**
- Intelligent update system with version management and rollback capabilities
- Responsibility: Safe and reliable system updates

**Service Module (stacker-service.sh)**
- Service lifecycle management for systemd, init.d, and standalone daemons
- Responsibility: Unified service control interface

**CLI Interface (integrated)**
- Complete command-line interface with interactive commands, argument parsing, and comprehensive help system
- Responsibility: Direct CLI execution, user interaction, and command processing with full subcommand support

**Self-Update Module (stacker-self-update.sh)**
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

### Interactive CLI Interface
Complete command-line interface with interactive mode, comprehensive help system, short aliases, and intelligent argument parsing

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
stacker init [OPTIONS]  # Initialize Stacker framework in current directory
stacker config [get|set|list] [key] [value]  # Manage configuration settings
stacker install [--systemd|--cron|--manual] [options]  # Install Stacker-based application
stacker update [--check|--force]  # Update Stacker-based application
stacker service [start|stop|restart|status|enable|disable]  # Control Stacker service
stacker health [--verbose]  # Check system health and diagnostics
stacker status  # Show current status of Stacker-based application
stacker rollback [version]  # Rollback to previous version
stacker self-update [--check]  # Update Stacker framework itself
stacker version [--json]  # Show version information
stacker help [command]  # Show help information
```

### Detailed Command Reference

#### `init, -i` Command
**Purpose**: Initialize Stacker framework in current directory  
**Usage**: `stacker init [OPTIONS]`

**Options**:
- `--template, -t`: Project template (service, cli, library) (default: service)
- `--name, -n`: Project name
- `--repo`: Repository URL
- `--script`: Main script name

**Examples**:
```bash
stacker init  # Initialize with interactive prompts
stacker init --template&#x3D;cli --name&#x3D;mytool  # Initialize CLI application template
```

#### `config, -c` Command
**Purpose**: Manage configuration settings  
**Usage**: `stacker config [get|set|list] [key] [value]`


**Examples**:
```bash
stacker config list  # List all configuration settings
stacker config get update.interval  # Get specific configuration value
stacker config set update.interval 3600  # Set configuration value
```

#### `install` Command
**Purpose**: Install Stacker-based application  
**Usage**: `stacker install [--systemd|--cron|--manual] [options]`

**Options**:
- `--systemd`: Install as systemd service
- `--cron`: Install as cron job
- `--manual`: Manual installation (default)
- `--interval&#x3D;N`: Cron interval in minutes
- `--auto-update, -a`: Enable automatic updates
- `--redundant`: Both systemd and cron

**Examples**:
```bash
stacker install --systemd  # Install as system service
stacker install --cron --interval&#x3D;300  # Install with 5-minute cron schedule
```

#### `update, -u` Command
**Purpose**: Update Stacker-based application  
**Usage**: `stacker update [--check|--force]`

**Options**:
- `--check`: Check for updates without installing
- `--force`: Force update even if current
- `--rollback`: Rollback to previous version

**Examples**:
```bash
stacker update --check  # Check for available updates
stacker update  # Perform update if available
```

#### `service, -s` Command
**Purpose**: Control Stacker service  
**Usage**: `stacker service [start|stop|restart|status|enable|disable]`


**Examples**:
```bash
stacker service start  # Start the service
stacker service status  # Check service status
stacker service enable  # Enable service at boot
```

#### `health` Command
**Purpose**: Check system health and diagnostics  
**Usage**: `stacker health [--verbose]`

**Options**:
- `--verbose`: Show detailed diagnostic information

**Examples**:
```bash
stacker health  # Quick health check
stacker health --verbose  # Detailed system diagnostics
```

#### `status` Command
**Purpose**: Show current status of Stacker-based application  
**Usage**: `stacker status`


**Examples**:
```bash
stacker status  # Display installation and service status
```

#### `rollback, -r` Command
**Purpose**: Rollback to previous version  
**Usage**: `stacker rollback [version]`


**Examples**:
```bash
stacker rollback  # Rollback to previous version
stacker rollback 1.2.3  # Rollback to specific version
```

#### `self-update` Command
**Purpose**: Update Stacker framework itself  
**Usage**: `stacker self-update [--check]`

**Options**:
- `--check`: Check for framework updates
- `--channel`: Update channel (stable, beta) (default: stable)

**Examples**:
```bash
stacker self-update --check  # Check for Stacker updates
stacker self-update  # Update Stacker framework
```

#### `version, -v` Command
**Purpose**: Show version information  
**Usage**: `stacker version [--json]`

**Options**:
- `--json`: Output in JSON format


#### `help, -h` Command
**Purpose**: Show help information  
**Usage**: `stacker help [command]`


**Examples**:
```bash
stacker help  # Show general help
stacker help install  # Show help for install command
```


## Environment Variables

### STACKER_CONFIG_DIR
- **Description**: Override default config directory
- **Default**: `$HOME/.config/stacker`

### STACKER_DATA_DIR
- **Description**: Override default data directory
- **Default**: `$HOME/.local/share/stacker`

### STACKER_LOG_LEVEL
- **Description**: Logging level (debug, info, warn, error)
- **Default**: `info`

### STACKER_UPDATE_CHANNEL
- **Description**: Update channel (stable, beta, nightly)
- **Default**: `stable`

### STACKER_AUTO_UPDATE
- **Description**: Enable automatic updates
- **Default**: `false`

### STACKER_PREFIX
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
stacker.sh              # Main entry point
├── Core Functions
│   ├── stacker_init()      # Framework initialization
│   ├── stacker_config()    # Configuration management
│   └── stacker_error()     # Error handling
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
STACKER_MODULE_NAME="module-name"
STACKER_MODULE_VERSION="1.0.0"
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
STACKER_DEBUG=true stacker init

# Check module path
echo $STACKER_MODULE_PATH

# Verify module syntax
sh -n module-name.sh
```

**Configuration Issues**
```bash
# Check configuration
stacker config list

# Validate configuration file
stacker config validate

# Reset configuration
rm -rf ~/.config/stacker
stacker init
```

**Service Issues**
```bash
# Check service status
stacker service status

# View service logs
journalctl -u stacker -f

# Restart service
stacker service restart
```

## Notes for AI Assistants

When working with Stacker:

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
When extending Stacker:
1. Create new module following the pattern
2. Add module to the module registry
3. Update configuration schema if needed
4. Add tests for new functionality
5. Document in module header

## Why Stacker Matters

Stacker is the foundational framework that brings consistency and reliability to shell-based system management. While modern tools require complex dependencies and runtimes, Stacker provides a universal, dependency-free solution that works everywhere, forever.

### Benefits
- No dependencies means no dependency hell
- POSIX compliance ensures universal compatibility
- Standardized patterns reduce complexity and errors
- Framework approach enables rapid development
- Battle-tested reliability for production systems
- Emergency recovery when other systems fail
- Educational resource for shell best practices

---

*Stacker is the foundation - bringing order to chaos through universal shell patterns.*

*Version: 2.0.0 | License: MIT | Author: AKAO.IO*