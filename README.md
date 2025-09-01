# @akaoio/stacker

Universal POSIX shell framework for system management - The foundational framework that standardizes patterns across all technologies with modular architecture

> Stacker brings order to chaos - a universal shell framework with modular loading that works everywhere, forever.

**Version**: 0.0.1  
**License**: MIT  
**Repository**: https://github.com/akaoio/stacker

## Overview

Stacker is a comprehensive shell framework that provides standardized patterns for system management, configuration, installation, updates, and service orchestration. Version 0.0.1 features a complete CLI interface with interactive commands and comprehensive help system.

## Core Principles

### Universal POSIX Compliance
Pure POSIX shell implementation that runs on any Unix-like system without dependencies
**Critical**: This is a foundational requirement

### Framework Pattern Standardization
Establishes universal patterns for shell-based system management across all environments
**Critical**: This is a foundational requirement

### Zero Dependencies
No external dependencies, no runtimes, no package stackers - just pure shell
**Critical**: This is a foundational requirement

### Eternal Infrastructure
Built to last forever - when languages come and go, Stacker remains
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
# Method 1: Git clone (recommended)
git clone https://github.com/akaoio/stacker.git
cd stacker
./install.sh

# Method 2: One-liner install
curl -fsSL https://raw.githubusercontent.com/akaoio/stacker/main/install.sh | sh

# Method 3: Manual download
wget https://github.com/akaoio/stacker/releases/latest/download/stacker.sh
chmod +x stacker.sh
```

## Usage

```bash
# Initialize a new Stacker-based project
stacker init

# Configure settings
stacker config set update.interval 3600

# Install application
stacker install --systemd

# Check health
stacker health

# Update application
stacker update
```

## Commands

### `init, -i`
Initialize Stacker framework in current directory

**Usage**: `stacker init [OPTIONS]`

**Options**:
- `--template, -t`: Project template (service, cli, library) (default: service)
- `--name, -n`: Project name
- `--repo`: Repository URL
- `--script`: Main script name

**Examples**:
- `stacker init` - Initialize with interactive prompts
- `stacker init --template cli --name mytool` - Initialize CLI application template

### `config, -c`
Manage configuration settings

**Usage**: `stacker config [get|set|list] [key] [value]`


**Examples**:
- `stacker config list` - List all configuration settings
- `stacker config get update.interval` - Get specific configuration value
- `stacker config set update.interval 3600` - Set configuration value

### `install`
Install Stacker-based application

**Usage**: `stacker install [--systemd|--cron|--manual] [options]`

**Options**:
- `--systemd`: Install as systemd service
- `--cron`: Install as cron job
- `--manual`: Manual installation (default)
- `--interval&#x3D;N`: Cron interval in minutes
- `--auto-update, -a`: Enable automatic updates
- `--redundant`: Both systemd and cron

**Examples**:
- `stacker install --systemd` - Install as system service
- `stacker install --cron --interval&#x3D;300` - Install with 5-minute cron schedule

### `update, -u`
Update Stacker-based application

**Usage**: `stacker update [--check|--force]`

**Options**:
- `--check`: Check for updates without installing
- `--force`: Force update even if current
- `--rollback`: Rollback to previous version

**Examples**:
- `stacker update --check` - Check for available updates
- `stacker update` - Perform update if available

### `service, -s`
Control Stacker service

**Usage**: `stacker service [start|stop|restart|status|enable|disable]`


**Examples**:
- `stacker service start` - Start the service
- `stacker service status` - Check service status
- `stacker service enable` - Enable service at boot

### `health`
Check system health and diagnostics

**Usage**: `stacker health [--verbose]`

**Options**:
- `--verbose`: Show detailed diagnostic information

**Examples**:
- `stacker health` - Quick health check
- `stacker health --verbose` - Detailed system diagnostics

### `status`
Show current status of Stacker-based application

**Usage**: `stacker status`


**Examples**:
- `stacker status` - Display installation and service status

### `rollback, -r`
Rollback to previous version

**Usage**: `stacker rollback [version]`


**Examples**:
- `stacker rollback` - Rollback to previous version
- `stacker rollback 1.2.3` - Rollback to specific version

### `self-update`
Update Stacker framework itself

**Usage**: `stacker self-update [--check]`

**Options**:
- `--check`: Check for framework updates
- `--channel`: Update channel (stable, beta) (default: stable)

**Examples**:
- `stacker self-update --check` - Check for Stacker updates
- `stacker self-update` - Update Stacker framework

### `version, -v`
Show version information

**Usage**: `stacker version [--json]`

**Options**:
- `--json`: Output in JSON format


### `help, -h`
Show help information

**Usage**: `stacker help [command]`


**Examples**:
- `stacker help` - Show general help
- `stacker help install` - Show help for install command


## Architecture

### Modular Shell Framework
Stacker uses a clean modular architecture with dynamic loading:

```
stacker/
├── stacker.sh              # Main entry point
├── install.sh              # XDG-compliant installer
├── VERSION                 # Single source of truth
└── src/sh/
    ├── loader.sh           # Module loading system
    └── module/             # Implementation modules
        ├── core.sh         # Core utilities & logging
        ├── cli.sh          # Command-line interface
        ├── config.sh       # Configuration management
        ├── install.sh      # Installation workflows
        ├── service.sh      # Service management
        ├── update.sh       # Update system
        ├── package.sh      # Package management
        └── watchdog.sh     # Health monitoring
```

### Module Loading
- **Dynamic loading**: Modules loaded only when needed
- **Dependency resolution**: Automatic dependency loading
- **POSIX compliance**: Pure shell implementation

### CLI Interface (integrated)
Complete command-line interface with interactive commands, argument parsing, and comprehensive help system

**Responsibility**: Direct CLI execution, user interaction, and command processing with full subcommand support

### Self-Update Module (stacker-self-update.sh)
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
| `STACKER_DEBUG` | Enable debug logging | `false` |
| `XDG_CONFIG_HOME` | XDG config directory | `$HOME/.config` |
| `XDG_DATA_HOME` | XDG data directory | `$HOME/.local/share` |
| `XDG_STATE_HOME` | XDG state directory | `$HOME/.local/state` |
| `XDG_CACHE_HOME` | XDG cache directory | `$HOME/.cache` |

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

## Development

Stacker follows strict POSIX compliance and zero-dependency principles. All code must be pure POSIX shell without bashisms or GNU extensions.

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

- **Issues**: [GitHub Issues](https://github.com/akaoio/stacker/issues)
- **Documentation**: [Wiki](https://github.com/akaoio/stacker/wiki)
- **Community**: [Discussions](https://github.com/akaoio/stacker/discussions)

---

*@akaoio/stacker - The foundational framework that brings order to chaos*

*Built with zero dependencies for eternal reliability*