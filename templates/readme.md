# {{project.name}}

{{project.description}}

> {{project.philosophy}}

**Version**: {{project.version}}  
**License**: {{project.license}}  
**Repository**: {{project.repository}}

## Overview

{{architecture.overview}}

## Core Principles

{{#each core_principles}}
### {{this.title}}
{{this.description}}
{{#if this.critical}}
**Critical**: This is a foundational requirement
{{/if}}

{{/each}}

## Features

{{#each features}}
- **{{this.name}}**: {{this.description}}
{{/each}}

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

{{#each commands.subcommands}}
### `{{this.name}}`
{{this.description}}

**Usage**: `{{this.usage}}`

{{#if this.options}}
**Options**:
{{#each this.options}}
- `{{this.flag}}`: {{this.description}}{{#if this.default}} (default: {{this.default}}){{/if}}
{{/each}}
{{/if}}

{{#if this.examples}}
**Examples**:
{{#each this.examples}}
- `{{this.command}}` - {{this.description}}
{{/each}}
{{/if}}

{{/each}}

## Architecture Components

{{#each architecture.components}}
### {{this.name}}
{{this.description}}

**Responsibility**: {{this.responsibility}}

{{/each}}

## Use Cases

{{#each use_cases}}
- {{this}}
{{/each}}

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
{{#each environment_variables}}
| `{{this.name}}` | {{this.description}} | `{{this.default}}` |
{{/each}}

## {{why_manager.title}}

{{why_manager.description}}

### Benefits

{{#each why_manager.benefits}}
- {{this}}
{{/each}}

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

*{{project.name}} - The foundational framework that brings order to chaos*

*Built with zero dependencies for eternal reliability*