#!/bin/sh
# POSIX compliance test for manager framework
# Tests the framework on different shells and validates POSIX compliance

set -e

# Test configuration
TEST_DIR="$(dirname "$0")"
MANAGER_DIR="$(dirname "$TEST_DIR")"
TEST_LOG="/tmp/manager-posix-test.log"

# Colors for test output
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    NC=''
fi

# Logging functions
test_log() {
    printf "%s[TEST]%s %s\n" "$GREEN" "$NC" "$*"
    printf "[%s] TEST: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$TEST_LOG"
}

test_error() {
    printf "%s[ERROR]%s %s\n" "$RED" "$NC" "$*" >&2
    printf "[%s] ERROR: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$TEST_LOG"
}

test_warn() {
    printf "%s[WARN]%s %s\n" "$YELLOW" "$NC" "$*" >&2
    printf "[%s] WARN: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$TEST_LOG"
}

# Find available POSIX shells
find_shells() {
    local shells=""
    
    for shell in /bin/sh /bin/dash /bin/ash /bin/bash /usr/bin/bash /bin/ksh /bin/mksh /bin/zsh; do
        if [ -x "$shell" ]; then
            shells="$shells $shell"
        fi
    done
    
    printf "%s" "$shells"
}

# Test shell syntax compliance
test_shell_syntax() {
    local shell="$1"
    local file="$2"
    
    if ! "$shell" -n "$file" 2>/dev/null; then
        return 1
    fi
    return 0
}

# Test for bashisms using checkbashisms if available
test_bashisms() {
    local file="$1"
    
    if ! command -v checkbashisms >/dev/null 2>&1; then
        test_warn "checkbashisms not available - skipping bashism detection for $file"
        return 0
    fi
    
    if checkbashisms "$file" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Test XDG compliance
test_xdg_compliance() {
    local temp_home temp_xdg_config temp_xdg_data
    
    # Create temporary environment
    temp_home=$(mktemp -d)
    temp_xdg_config="$temp_home/.config"
    temp_xdg_data="$temp_home/.local/share"
    
    export HOME="$temp_home"
    export XDG_CONFIG_HOME="$temp_xdg_config"
    export XDG_DATA_HOME="$temp_xdg_data"
    
    # Source core functions
    . "$MANAGER_DIR/manager-core-posix.sh"
    
    # Test XDG directory creation
    MANAGER_TECH_NAME="testapp"
    if ! manager_create_xdg_dirs; then
        test_error "Failed to create XDG directories"
        rm -rf "$temp_home"
        return 1
    fi
    
    # Verify directories were created in correct locations
    if [ ! -d "$temp_xdg_config/testapp" ] || [ ! -d "$temp_xdg_data/testapp" ]; then
        test_error "XDG directories not created in correct locations"
        rm -rf "$temp_home"
        return 1
    fi
    
    # Clean up
    rm -rf "$temp_home"
    unset HOME XDG_CONFIG_HOME XDG_DATA_HOME MANAGER_TECH_NAME
    
    return 0
}

# Test core functions
test_core_functions() {
    local temp_script
    
    temp_script=$(mktemp)
    
    # Create test script with proper path
    cat > "$temp_script" << EOF
#!/bin/sh
# Test script for core functions

MANAGER_DIR="$MANAGER_DIR"
. "\$MANAGER_DIR/manager-core-posix.sh"

# Test logging functions
manager_log "Test log message"
manager_info "Test info message" 
manager_warn "Test warning message"
manager_error "Test error message"

# Test OS detection
OS=$(manager_detect_os)
if [ -z "$OS" ]; then
    exit 1
fi

# Test package manager detection
PM=$(manager_detect_package_manager)
if [ -z "$PM" ]; then
    exit 1
fi

# Test user detection
USER=$(manager_get_user)
if [ -z "$USER" ]; then
    exit 1
fi

# Test temp file creation
TEMP_FILE=$(manager_create_temp_file)
if [ ! -f "$TEMP_FILE" ]; then
    exit 1
fi
rm -f "$TEMP_FILE"

# Test input validation
if ! manager_validate_input "/valid/path" "path"; then
    exit 1
fi

if manager_validate_input "../invalid/path" "path"; then
    exit 1
fi

exit 0
EOF
    
    chmod +x "$temp_script"
    
    # Test with different shells
    local shells success=0 total=0
    shells=$(find_shells)
    
    for shell in $shells; do
        total=$((total + 1))
        if "$shell" "$temp_script" 2>/dev/null; then
            test_log "Core functions test passed with $shell"
            success=$((success + 1))
        else
            test_error "Core functions test failed with $shell"
        fi
    done
    
    rm -f "$temp_script"
    
    if [ "$success" -eq "$total" ]; then
        return 0
    else
        return 1
    fi
}

# Test POSIX compliance for all manager files
test_all_manager_files() {
    local files shells shell file success=0 total=0
    
    files="$MANAGER_DIR/manager.sh $MANAGER_DIR/manager-core-posix.sh $MANAGER_DIR/manager-self-update-posix.sh"
    shells=$(find_shells)
    
    test_log "Testing POSIX compliance for manager framework files"
    
    for file in $files; do
        if [ ! -f "$file" ]; then
            test_warn "File not found: $file"
            continue
        fi
        
        test_log "Testing file: $(basename "$file")"
        
        # Test syntax with different shells
        for shell in $shells; do
            total=$((total + 1))
            if test_shell_syntax "$shell" "$file"; then
                test_log "  ✓ Syntax OK with $(basename "$shell")"
                success=$((success + 1))
            else
                test_error "  ✗ Syntax failed with $(basename "$shell")"
            fi
        done
        
        # Test for bashisms
        if test_bashisms "$file"; then
            test_log "  ✓ No bashisms detected"
        else
            test_error "  ✗ Bashisms detected in $file"
        fi
    done
    
    test_log "Syntax tests: $success/$total passed"
    
    if [ "$success" -eq "$total" ]; then
        return 0
    else
        return 1
    fi
}

# Test XDG environment variable handling
test_xdg_env_handling() {
    local temp_script
    
    temp_script=$(mktemp)
    
    cat > "$temp_script" << EOF
#!/bin/sh
MANAGER_DIR="$MANAGER_DIR"
. "\$MANAGER_DIR/manager-core-posix.sh"

# Test with custom XDG paths
export XDG_CONFIG_HOME="/tmp/test-config"
export XDG_DATA_HOME="/tmp/test-data"

# Check that variables are respected
if [ "$MANAGER_XDG_CONFIG_HOME" != "/tmp/test-config" ]; then
    exit 1
fi

if [ "$MANAGER_XDG_DATA_HOME" != "/tmp/test-data" ]; then
    exit 1
fi

exit 0
EOF
    
    chmod +x "$temp_script"
    
    if sh "$temp_script"; then
        test_log "XDG environment variable handling test passed"
        rm -f "$temp_script"
        return 0
    else
        test_error "XDG environment variable handling test failed"
        rm -f "$temp_script"
        return 1
    fi
}

# Main test runner
run_all_tests() {
    local tests_passed=0 tests_total=0
    
    printf "========================================\n"
    printf "  Manager Framework POSIX Compliance Test\n"  
    printf "========================================\n"
    printf "\n"
    
    test_log "Starting POSIX compliance tests..."
    test_log "Available shells: $(find_shells)"
    printf "\n"
    
    # Test 1: File syntax compliance
    tests_total=$((tests_total + 1))
    test_log "Test 1: File syntax compliance"
    if test_all_manager_files; then
        test_log "✓ PASSED: File syntax compliance"
        tests_passed=$((tests_passed + 1))
    else
        test_error "✗ FAILED: File syntax compliance"
    fi
    printf "\n"
    
    # Test 2: Core functions
    tests_total=$((tests_total + 1))
    test_log "Test 2: Core functions"
    if test_core_functions; then
        test_log "✓ PASSED: Core functions"
        tests_passed=$((tests_passed + 1))
    else
        test_error "✗ FAILED: Core functions"
    fi
    printf "\n"
    
    # Test 3: XDG compliance
    tests_total=$((tests_total + 1))
    test_log "Test 3: XDG Base Directory compliance"
    if test_xdg_compliance; then
        test_log "✓ PASSED: XDG compliance"
        tests_passed=$((tests_passed + 1))
    else
        test_error "✗ FAILED: XDG compliance"
    fi
    printf "\n"
    
    # Test 4: XDG environment handling
    tests_total=$((tests_total + 1))
    test_log "Test 4: XDG environment variable handling"
    if test_xdg_env_handling; then
        test_log "✓ PASSED: XDG environment handling"
        tests_passed=$((tests_passed + 1))
    else
        test_error "✗ FAILED: XDG environment handling"
    fi
    printf "\n"
    
    # Final results
    printf "========================================\n"
    printf "  Test Results\n"
    printf "========================================\n"
    printf "Tests passed: %d/%d\n" "$tests_passed" "$tests_total"
    printf "Test log: %s\n" "$TEST_LOG"
    printf "\n"
    
    if [ "$tests_passed" -eq "$tests_total" ]; then
        test_log "🎉 All POSIX compliance tests PASSED!"
        printf "%s✅ Manager framework is POSIX compliant%s\n" "$GREEN" "$NC"
        return 0
    else
        test_error "❌ Some tests FAILED - framework needs fixes"
        printf "%s❌ Manager framework has POSIX compliance issues%s\n" "$RED" "$NC"
        return 1
    fi
}

# Check for required tools
check_test_requirements() {
    local missing=""
    
    if ! command -v mktemp >/dev/null 2>&1; then
        missing="$missing mktemp"
    fi
    
    if [ -n "$missing" ]; then
        test_error "Missing required tools for testing:$missing"
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    if ! check_test_requirements; then
        exit 1
    fi
    
    # Clean up old log
    rm -f "$TEST_LOG"
    
    # Run all tests
    run_all_tests
    exit $?
}

# Handle command line arguments
case "${1:-}" in
    --syntax-only)
        test_all_manager_files
        ;;
    --core-only)
        test_core_functions
        ;;
    --xdg-only)
        test_xdg_compliance
        ;;
    --help)
        printf "Manager Framework POSIX Compliance Test\n"
        printf "\n"
        printf "Usage: %s [option]\n" "$0"
        printf "\n"
        printf "Options:\n"
        printf "  --syntax-only    Test syntax compliance only\n"
        printf "  --core-only      Test core functions only\n"
        printf "  --xdg-only       Test XDG compliance only\n"
        printf "  --help           Show this help\n"
        printf "\n"
        printf "Without options, runs all tests.\n"
        ;;
    *)
        main
        ;;
esac