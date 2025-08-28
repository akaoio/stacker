# @akaoio/manager

Universal POSIX shell framework for system management - The foundational framework that standardizes patterns across all technologies

> Manager brings order to chaos - a universal shell framework that works everywhere, forever.

**Version**: 1.0.0  
**License**: MIT  
**Repository**: https://github.com/akaoio/manager

## Overview

Manager is a comprehensive shell framework that provides standardized patterns for system management, configuration, installation, updates, and service orchestration.

## Core Principles


### Universal POSIX Compliance
Pure POSIX shell implementation that runs on any Unix-like system without dependencies



### Framework Pattern Standardization
Establishes universal patterns for shell-based system management across all environments



### Zero Dependencies
No external dependencies, no runtimes, no package managers - just pure shell



### Eternal Infrastructure
Built to last forever - when languages come and go, Manager remains




## Features


- **Universal Shell Patterns**: Standardized patterns for error handling, logging, configuration, and state management

- **XDG Compliance**: Full XDG Base Directory specification compliance for configuration and data storage

- **Multi-Platform Support**: Works on Linux, BSD, macOS, and any POSIX-compliant system

- **Service Integration**: Native integration with systemd, init.d, launchd, and cron

- **Atomic Operations**: Safe atomic updates and rollback capabilities for critical operations

- **Modular Architecture**: Clean separation of concerns with independent, reusable modules

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


### `init`
Initialize Manager framework in current directory

**Usage**: `manager init [--template=TYPE]`



### `config`
Manage configuration settings

**Usage**: `manager config [get|set|list] [key] [value]`



### `install`
Install Manager-based application

**Usage**: `manager install [--systemd|--cron|--manual] [options]`



### `update`
Update Manager-based application

**Usage**: `manager update [--check|--force]`



### `service`
Control Manager service

**Usage**: `manager service [start|stop|restart|status|enable|disable]`



### `health`
Check system health and diagnostics

**Usage**: `manager health [--verbose]`



### `rollback`
Rollback to previous version

**Usage**: `manager rollback [version]`



### `self-update`
Update Manager framework itself

**Usage**: `manager self-update [--check]`



### `version`
Show version information

**Usage**: `manager version [--json]`



### `help`
Show help information

**Usage**: `manager help [command]`









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


### CLI Module (manager-cli.sh)
Command-line interface with subcommand routing and argument parsing

**Responsibility**: User interaction and command processing


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