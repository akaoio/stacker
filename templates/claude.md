# CLAUDE.md - {{project.name}}

This file provides guidance to Claude Code (claude.ai/code) when working with the {{project.name}} codebase.

## Project Overview

**{{project.name}}** - {{project.description}}

**Version**: {{project.version}}  
**License**: {{project.license}}  
**Author**: {{project.author}}  
**Repository**: {{project.repository}}  
**Philosophy**: "{{project.philosophy}}"

## Core Development Principles

{{#each core_principles}}
### {{this.title}}
{{this.description}}
{{#if this.critical}}
**Critical**: true
{{/if}}

{{/each}}

## Architecture Overview

### System Design

{{architecture.overview}}

### Core Components

{{#each architecture.components}}
**{{this.name}}**
- {{this.description}}
- Responsibility: {{this.responsibility}}

{{/each}}

## Features

{{#each features}}
### {{this.name}}
{{this.description}}

{{/each}}

## Command Interface

### Core Commands

```bash
{{#each commands.subcommands}}
{{this.usage}}  # {{this.description}}
{{/each}}
```

### Detailed Command Reference

{{#each commands.subcommands}}
#### `{{this.name}}` Command
**Purpose**: {{this.description}}  
**Usage**: `{{this.usage}}`

{{#if this.options}}
**Options**:
{{#each this.options}}
- `{{this.flag}}`: {{this.description}}{{#if this.default}} (default: {{this.default}}){{/if}}
{{/each}}
{{/if}}

{{#if this.examples}}
**Examples**:
```bash
{{#each this.examples}}
{{this.command}}  # {{this.description}}
{{/each}}
```
{{/if}}

{{/each}}

## Environment Variables

{{#each environment_variables}}
### {{this.name}}
- **Description**: {{this.description}}
- **Default**: `{{this.default}}`

{{/each}}

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

{{#each use_cases}}
### {{@index}}. {{this}}
{{/each}}

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

## {{why_manager.title}}

{{why_manager.description}}

### Benefits
{{#each why_manager.benefits}}
- {{this}}
{{/each}}

---

*Manager is the foundation - bringing order to chaos through universal shell patterns.*

*Version: {{project.version}} | License: {{project.license}} | Author: {{project.author}}*