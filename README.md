# @akaoio/manager

Universal POSIX shell framework for system management - The foundational framework that standardizes patterns across all technologies with modular architecture

> Manager brings order to chaos - a universal shell framework with modular loading that works everywhere, forever.

**Version**: 2.0.0  
**License**: MIT  
**Repository**: https://github.com/akaoio/manager

## Overview

Manager is a comprehensive shell framework that provides standardized patterns for system management, configuration, installation, updates, and service orchestration. Version 2.0.0 features a complete CLI interface with interactive commands and comprehensive help system.

## Core Principles

### Universal POSIX Compliance
Pure POSIX shell implementation that runs on any Unix-like system without dependencies
**Critical**: This is a foundational requirement

### Framework Pattern Standardization
Establishes universal patterns for shell-based system management across all environments
**Critical**: This is a foundational requirement

### Zero Dependencies
No external dependencies, no runtimes, no package managers - just pure shell
**Critical**: This is a foundational requirement

### Eternal Infrastructure
Built to last forever - when languages come and go, Manager remains
**Critical**: This is a foundational requirement


## Features

- **Universal Shell Patterns**: Standardized patterns for error handling, logging, configuration, and state management
- **Dynamic Module Loading**: On-demand module loading with automatic dependency resolution and smart caching
- **Modular Architecture**: Clean separation of concerns with independent, reusable modules that load only when needed
- **Module Registry System**: Comprehensive module tracking, dependency management, and initialization lifecycle
- **Auto-Loading Intelligence**: Smart function detection that automatically loads required modules based on function calls
- **Interactive CLI Interface**: Complete command-line interface with interactive mode, comprehensive help system, short aliases, and intelligent argument parsing
- **XDG Compliance**: Full XDG Base Directory specification compliance for configuration and data storage
- **Multi-Platform Support**: Works on Linux, BSD, macOS, and any POSIX-compliant system
- **Service Integration**: Native integration with systemd, init.d, launchd, and cron
- **Atomic Operations**: Safe atomic updates and rollback capabilities for critical operations
- **Version Management**: Semantic versioning with compatibility checking and migration support
- **Health Monitoring**: Built-in health checks and diagnostic capabilities

## Installation

```bash
# Quick install with default settings
curl -sSL https://raw.githubusercontent.com/akaoio/manager/main/install.sh | sh

# Install as systemd service
curl -sSL https://raw.githubusercontent.com/akaoio/manager/main/install.sh | sh -s -- --systemd

# Install with custom prefix
curl -sSL https://raw.githubusercontent.com/akaoio/manager/main/install.sh | sh -s -- --prefix=/opt/manager
```

## Usage

```bash
# Initialize a new Manager-based project
manager init

# Configure settings
manager config set update.interval 3600

# Install application
manager install --systemd

# Check health
manager health

# Update application
manager update
```

## Commands

### `init, -i`
Initialize Manager framework in current directory

**Usage**: `manager init [OPTIONS]`

**Options**:
- `--template, -t`: Project template (service, cli, library) (default: service)
- `--name, -n`: Project name
- `--repo`: Repository URL
- `--script`: Main script name

**Examples**:
- `manager init` - Initialize with interactive prompts
- `manager init --template&#x3D;cli --name&#x3D;mytool` - Initialize CLI application template

### `config, -c`
Manage configuration settings

**Usage**: `manager config [get|set|list] [key] [value]`


**Examples**:
- `manager config list` - List all configuration settings
- `manager config get update.interval` - Get specific configuration value
- `manager config set update.interval 3600` - Set configuration value

### `install`
Install Manager-based application

**Usage**: `manager install [--systemd|--cron|--manual] [options]`

**Options**:
- `--systemd`: Install as systemd service
- `--cron`: Install as cron job
- `--manual`: Manual installation (default)
- `--interval&#x3D;N`: Cron interval in minutes
- `--auto-update, -a`: Enable automatic updates
- `--redundant`: Both systemd and cron

**Examples**:
- `manager install --systemd` - Install as system service
- `manager install --cron --interval&#x3D;300` - Install with 5-minute cron schedule

### `update, -u`
Update Manager-based application

**Usage**: `manager update [--check|--force]`

**Options**:
- `--check`: Check for updates without installing
- `--force`: Force update even if current
- `--rollback`: Rollback to previous version

**Examples**:
- `manager update --check` - Check for available updates
- `manager update` - Perform update if available

### `service, -s`
Control Manager service

**Usage**: `manager service [start|stop|restart|status|enable|disable]`


**Examples**:
- `manager service start` - Start the service
- `manager service status` - Check service status
- `manager service enable` - Enable service at boot

### `health`
Check system health and diagnostics

**Usage**: `manager health [--verbose]`

**Options**:
- `--verbose`: Show detailed diagnostic information

**Examples**:
- `manager health` - Quick health check
- `manager health --verbose` - Detailed system diagnostics

### `status`
Show current status of Manager-based application

**Usage**: `manager status`


**Examples**:
- `manager status` - Display installation and service status

### `rollback, -r`
Rollback to previous version

**Usage**: `manager rollback [version]`


**Examples**:
- `manager rollback` - Rollback to previous version
- `manager rollback 1.2.3` - Rollback to specific version

### `self-update`
Update Manager framework itself

**Usage**: `manager self-update [--check]`

**Options**:
- `--check`: Check for framework updates
- `--channel`: Update channel (stable, beta) (default: stable)

**Examples**:
- `manager self-update --check` - Check for Manager updates
- `manager self-update` - Update Manager framework

### `version, -v`
Show version information

**Usage**: `manager version [--json]`

**Options**:
- `--json`: Output in JSON format


### `help, -h`
Show help information

**Usage**: `manager help [command]`


**Examples**:
- `manager help` - Show general help
- `manager help install` - Show help for install command


## Architecture Components

### Core Module (manager-core.sh)
Central framework providing common functions, error handling, logging, and state management

**Responsibility**: Foundation layer for all Manager operations

### Configuration Module (manager-config.sh)
XDG-compliant configuration management with JSON support and environment variable overrides

**Responsibility**: Centralized configuration handling across all modules

### Installation Module (manager-install.sh)
Universal installation framework supporting systemd, cron, and manual deployment

**Responsibility**: Standardized installation across different environments

### Update Module (manager-update.sh)
Intelligent update system with version management and rollback capabilities

**Responsibility**: Safe and reliable system updates

### Service Module (manager-service.sh)
Service lifecycle management for systemd, init.d, and standalone daemons

**Responsibility**: Unified service control interface

### CLI Interface (integrated)
Complete command-line interface with interactive commands, argument parsing, and comprehensive help system

**Responsibility**: Direct CLI execution, user interaction, and command processing with full subcommand support

### Self-Update Module (manager-self-update.sh)
Auto-update capability with integrity verification and atomic updates

**Responsibility**: Framework self-maintenance


## Use Cases

- System initialization and bootstrapping
- Application deployment and management
- Service orchestration and monitoring
- Configuration management across environments
- Automated updates and maintenance
- Cross-platform shell script development
- Infrastructure automation without dependencies
- Emergency recovery systems

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MANAGER_CONFIG_DIR` | Override default config directory | `$HOME/.config/manager` |
| `MANAGER_DATA_DIR` | Override default data directory | `$HOME/.local/share/manager` |
| `MANAGER_LOG_LEVEL` | Logging level (debug, info, warn, error) | `info` |
| `MANAGER_UPDATE_CHANNEL` | Update channel (stable, beta, nightly) | `stable` |
| `MANAGER_AUTO_UPDATE` | Enable automatic updates | `false` |
| `MANAGER_PREFIX` | Installation prefix | `/usr/local` |

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

## Development

Manager follows strict POSIX compliance and zero-dependency principles. All code must be pure POSIX shell without bashisms or GNU extensions.

### Contributing

1. Fork the repository
2. Create your feature branch
3. Ensure POSIX compliance
4. Add tests using the test framework
5. Submit a pull request

### Testing

```bash
# Run all tests
./tests/run-all.sh

# Run specific test suite
./tests/test-core.sh
```

## Support

- **Issues**: [GitHub Issues](https://github.com/akaoio/manager/issues)
- **Documentation**: [Wiki](https://github.com/akaoio/manager/wiki)
- **Community**: [Discussions](https://github.com/akaoio/manager/discussions)

---

*@akaoio/manager - The foundational framework that brings order to chaos*

*Built with zero dependencies for eternal reliability*