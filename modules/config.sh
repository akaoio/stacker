#!/bin/sh
# Module: config
# Description: Configuration management functions with JSON support and environment overrides
# Dependencies: core
# Provides: JSON configuration loading, environment overrides, interactive setup, validation

# Module metadata
STACKER_MODULE_NAME="config"
STACKER_MODULE_VERSION="1.0.0"
STACKER_MODULE_DEPENDENCIES="core"
STACKER_MODULE_LOADED=false

# Module initialization
config_init() {
    STACKER_MODULE_LOADED=true
    stacker_debug "Config module initialized"
    return 0
}

# Load configuration from file and environment
stacker_load_config() {
    local config_file="$STACKER_CONFIG_DIR/config.json"
    local var_name value
    
    stacker_debug "Loading configuration from $config_file"
    
    # Create default config if it doesn't exist
    if [ ! -f "$config_file" ]; then
        stacker_create_default_config "$config_file" || return 1
    fi
    
    # Load configuration variables
    # This is a simple JSON parser for basic key-value pairs
    if command -v jq >/dev/null 2>&1; then
        # Use jq if available for proper JSON parsing
        stacker_load_config_with_jq "$config_file"
    else
        # Fallback to simple parsing for basic JSON
        stacker_load_config_simple "$config_file"
    fi
    
    # Override with environment variables
    stacker_load_env_overrides
    
    return 0
}

# Load configuration using jq (preferred method)
stacker_load_config_with_jq() {
    local config_file="$1"
    local key value
    
    # Export all configuration variables
    jq -r 'to_entries[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null | while IFS='=' read -r key value; do
        if [ -n "$key" ]; then
            tech_upper=$(stacker_to_upper "$STACKER_TECH_NAME")
            key_upper=$(stacker_to_upper "$key")
            export "${tech_upper}_${key_upper}=$value"
        fi
    done
}

# Simple configuration loader (fallback)
stacker_load_config_simple() {
    local config_file="$1"
    local line key value
    
    # Simple JSON parser - assumes one key-value pair per line
    while IFS= read -r line; do
        # Skip comments and empty lines
        case "$line" in
            ''|'#'*|'//'*) continue ;;
        esac
        
        # Extract key-value pairs (basic JSON parsing)
        echo "$line" | sed -n 's/.*"\([^"]*\)"\s*:\s*"\([^"]*\)".*/\1=\2/p' | while IFS='=' read -r key value; do
            if [ -n "$key" ]; then
                tech_upper=$(stacker_to_upper "$STACKER_TECH_NAME")
            key_upper=$(stacker_to_upper "$key")
            export "${tech_upper}_${key_upper}=$value"
            fi
        done
    done < "$config_file"
}

# Load environment variable overrides
stacker_load_env_overrides() {
    local prefix="$(stacker_to_upper "$STACKER_TECH_NAME")_"
    
    # Look for environment variables with the technology prefix
    env | grep "^$prefix" | while IFS='=' read -r var_name value; do
        stacker_debug "Environment override: $var_name=$value"
        export "$var_name=$value"
    done
}

# Create default configuration file
stacker_create_default_config() {
    local config_file="$1"
    local service_name="$STACKER_TECH_NAME"
    
    stacker_debug "Creating default configuration: $config_file"
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$config_file")" || return 1
    
    # Create basic configuration template
    cat > "$config_file" << EOF
{
    "service_name": "$service_name",
    "version": "1.0.0",
    "auto_update": true,
    "log_level": "info",
    "data_dir": "$STACKER_DATA_DIR",
    "state_dir": "$STACKER_STATE_DIR"
}
EOF
    
    # Set secure permissions
    chmod 600 "$config_file" || return 1
    
    stacker_debug "Default configuration created"
    return 0
}

# Save configuration to file
stacker_save_config() {
    local config_file="$STACKER_CONFIG_DIR/config.json"
    local key="$1"
    local value="$2"
    local temp_file
    
    if [ -z "$key" ]; then
        stacker_error "Configuration key is required"
        return 1
    fi
    
    stacker_debug "Saving configuration: $key=$value"
    
    # Create config if it doesn't exist
    if [ ! -f "$config_file" ]; then
        stacker_create_default_config "$config_file" || return 1
    fi
    
    # Update configuration
    temp_file=$(stacker_create_temp_file "config") || return 1
    
    if command -v jq >/dev/null 2>&1; then
        # Use jq for proper JSON manipulation
        jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$config_file" > "$temp_file" || {
            rm -f "$temp_file"
            stacker_error "Failed to update configuration with jq"
            return 1
        }
    else
        # Simple JSON manipulation (limited)
        if grep -q "\"$key\"" "$config_file"; then
            # Update existing key
            sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/" "$config_file" > "$temp_file"
        else
            # Add new key before closing brace
            sed "s/}$/,\n    \"$key\": \"$value\"\n}/" "$config_file" > "$temp_file"
        fi
    fi
    
    # Replace original file
    mv "$temp_file" "$config_file" || {
        rm -f "$temp_file"
        stacker_error "Failed to save configuration"
        return 1
    }
    
    # Set secure permissions
    chmod 600 "$config_file"
    
    stacker_debug "Configuration saved successfully"
    return 0
}

# Get configuration value
stacker_get_config() {
    local key="$1"
    local config_file="$STACKER_CONFIG_DIR/config.json"
    local tech_upper=$(stacker_to_upper "$STACKER_TECH_NAME")
    local key_upper=$(stacker_to_upper "$key")
    local env_var="${tech_upper}_${key_upper}"
    
    if [ -z "$key" ]; then
        stacker_error "Configuration key is required"
        return 1
    fi
    
    # Check environment variable first (highest priority)
    value=$(eval "echo \"\$$env_var\"")
    if [ -n "$value" ]; then
        echo "$value"
        return 0
    fi
    
    # Check configuration file
    if [ -f "$config_file" ]; then
        if command -v jq >/dev/null 2>&1; then
            jq -r ".$key // empty" "$config_file" 2>/dev/null
        else
            # Simple extraction
            grep "\"$key\"" "$config_file" | sed -n 's/.*"\([^"]*\)".*/\1/p' | head -1
        fi
    fi
}

# Validate configuration
stacker_validate_config() {
    local config_file="$STACKER_CONFIG_DIR/config.json"
    local service_name tech_name
    
    stacker_debug "Validating configuration: $config_file"
    
    if [ ! -f "$config_file" ]; then
        stacker_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Basic JSON syntax validation
    if command -v jq >/dev/null 2>&1; then
        if ! jq empty "$config_file" >/dev/null 2>&1; then
            stacker_error "Invalid JSON in configuration file"
            return 1
        fi
    fi
    
    # Validate required fields
    service_name=$(stacker_get_config "service_name")
    if [ -z "$service_name" ]; then
        stacker_error "Missing required configuration: service_name"
        return 1
    fi
    
    # Validate service name matches expected
    if [ "$service_name" != "$STACKER_TECH_NAME" ]; then
        stacker_warn "Service name mismatch: expected $STACKER_TECH_NAME, got $service_name"
    fi
    
    stacker_debug "Configuration validation passed"
    return 0
}

# Backup configuration
stacker_backup_config() {
    local config_file="$STACKER_CONFIG_DIR/config.json"
    local backup_dir="$STACKER_CONFIG_DIR/backups"
    local backup_file="$backup_dir/config.$(date +%Y%m%d-%H%M%S).json"
    
    if [ ! -f "$config_file" ]; then
        stacker_warn "No configuration file to backup"
        return 0
    fi
    
    stacker_debug "Backing up configuration to $backup_file"
    
    # Create backup directory
    mkdir -p "$backup_dir" || return 1
    
    # Copy configuration
    cp "$config_file" "$backup_file" || return 1
    
    # Cleanup old backups (keep last 10)
    ls -1t "$backup_dir"/config.*.json 2>/dev/null | tail -n +11 | while read -r old_backup; do
        rm -f "$old_backup"
    done
    
    stacker_debug "Configuration backed up successfully"
    return 0
}

# Restore configuration from backup
stacker_restore_config() {
    local backup_file="$1"
    local config_file="$STACKER_CONFIG_DIR/config.json"
    
    if [ -z "$backup_file" ]; then
        # Find most recent backup
        local backup_dir="$STACKER_CONFIG_DIR/backups"
        backup_file=$(ls -1t "$backup_dir"/config.*.json 2>/dev/null | head -1)
        
        if [ -z "$backup_file" ]; then
            stacker_error "No backup files found"
            return 1
        fi
        
        stacker_log "Using most recent backup: $backup_file"
    fi
    
    if [ ! -f "$backup_file" ]; then
        stacker_error "Backup file not found: $backup_file"
        return 1
    fi
    
    stacker_log "Restoring configuration from $backup_file"
    
    # Backup current config first
    if [ -f "$config_file" ]; then
        stacker_backup_config
    fi
    
    # Restore from backup
    cp "$backup_file" "$config_file" || return 1
    
    # Set secure permissions
    chmod 600 "$config_file"
    
    # Validate restored configuration
    if stacker_validate_config; then
        stacker_log "Configuration restored successfully"
        return 0
    else
        stacker_error "Restored configuration is invalid"
        return 1
    fi
}

# Interactive configuration setup
stacker_configure_interactive() {
    local config_file="$STACKER_CONFIG_DIR/config.json"
    local key value
    
    stacker_log "Interactive configuration for $STACKER_TECH_NAME"
    echo "=========================================="
    
    # Load existing configuration
    stacker_load_config
    
    # Configure basic settings
    echo "Basic Configuration:"
    echo ""
    
    printf "Service name [$STACKER_TECH_NAME]: "
    read -r value
    value="${value:-$STACKER_TECH_NAME}"
    stacker_save_config "service_name" "$value"
    
    printf "Enable auto-update [y/N]: "
    read -r value
    case "$value" in
        [Yy]|[Yy][Ee][Ss])
            stacker_save_config "auto_update" "true"
            ;;
        *)
            stacker_save_config "auto_update" "false"
            ;;
    esac
    
    printf "Log level (debug/info/warn/error) [info]: "
    read -r value
    value="${value:-info}"
    stacker_save_config "log_level" "$value"
    
    echo ""
    stacker_log "Interactive configuration completed"
    stacker_log "Configuration saved to: $config_file"
    
    return 0
}

# Show current configuration
stacker_show_config() {
    local config_file="$STACKER_CONFIG_DIR/config.json"
    
    echo "=========================================="
    echo "  $STACKER_TECH_NAME Configuration"
    echo "=========================================="
    echo ""
    
    if [ -f "$config_file" ]; then
        echo "Configuration file: $config_file"
        echo ""
        
        if command -v jq >/dev/null 2>&1; then
            jq '.' "$config_file" 2>/dev/null || cat "$config_file"
        else
            cat "$config_file"
        fi
    else
        echo "No configuration file found."
        echo "Run 'stacker_configure_interactive' to create one."
    fi
    
    echo ""
    echo "Environment overrides:"
    local prefix=$(stacker_to_upper "$STACKER_TECH_NAME")
    env | grep "^${prefix}_" || echo "  None"
    echo ""
    
    return 0
}

# Export public interface
config_list_functions() {
    echo "stacker_load_config stacker_save_config stacker_get_config"
    echo "stacker_validate_config stacker_backup_config stacker_restore_config"
    echo "stacker_configure_interactive stacker_show_config"
    echo "stacker_create_default_config stacker_load_env_overrides"
}