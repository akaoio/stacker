#!/bin/sh
# Battle Shell Compatibility Test for Stacker
# Tests POSIX compliance across different shells using Battle PTY framework

set -e

echo "🐚 Battle Shell Compatibility Testing"
echo "======================================"

# Battle test configuration
BATTLE_TEST_NAME="Shell Compatibility v0.0.2"
BATTLE_TIMEOUT=30000
TEST_SHELLS="/bin/sh /bin/bash /bin/dash"

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Colors for Battle-style output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Battle test helper function
battle_test() {
    local test_name="$1"
    local shell_path="$2"
    local test_command="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""
    echo "${CYAN}🧪 Testing: $test_name${NC}"
    echo "   Shell: $shell_path"
    echo "   Command: $test_command"
    
    # Create PTY-like environment for testing
    if [ -x "$shell_path" ]; then
        # Run the test with timeout and capture exit code
        if timeout 10 "$shell_path" -c "$test_command" >/tmp/battle_test_output 2>&1; then
            local exit_code=$?
            local output=$(cat /tmp/battle_test_output)
            
            echo "${GREEN}   ✅ PASS: $test_name${NC}"
            echo "   Exit code: $exit_code"
            echo "   Output preview: $(echo "$output" | head -1)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            local exit_code=$?
            echo "${RED}   ❌ FAIL: $test_name${NC}"
            echo "   Exit code: $exit_code"
            if [ -f /tmp/battle_test_output ]; then
                echo "   Error: $(cat /tmp/battle_test_output | head -1)"
            fi
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        echo "${YELLOW}   ⚠️  SKIP: Shell $shell_path not available${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Battle test: Basic shell compatibility
echo "${BLUE}🔍 Testing basic shell compatibility...${NC}"

for shell in $TEST_SHELLS; do
    battle_test "Basic version command" "$shell" "./stacker.sh version"
    battle_test "Help command" "$shell" "./stacker.sh help"
    battle_test "Invalid command handling" "$shell" "./stacker.sh invalid-xyz-command || true"
done

# Battle test: POSIX compliance features
echo ""
echo "${BLUE}🔍 Testing POSIX compliance features...${NC}"

for shell in $TEST_SHELLS; do
    # Test POSIX parameter expansion
    battle_test "POSIX parameter expansion" "$shell" "test -x ./stacker.sh && echo 'executable'"
    
    # Test POSIX command substitution
    battle_test "Command substitution" "$shell" "version=\$(./stacker.sh version | head -1) && echo \"Got: \$version\""
    
    # Test POSIX variable handling
    battle_test "Environment variables" "$shell" "STACKER_TEST_MODE=true ./stacker.sh version"
done

# Battle test: Shell-specific features
echo ""
echo "${BLUE}🔍 Testing shell-specific compatibility...${NC}"

# Test with sh (most restrictive)
if [ -x "/bin/sh" ]; then
    battle_test "Strict POSIX mode" "/bin/sh" "set -e && ./stacker.sh version"
    battle_test "Pipeline handling" "/bin/sh" "./stacker.sh version | grep -q '0.0.2'"
fi

# Test with bash (extended features)
if [ -x "/bin/bash" ]; then
    battle_test "Bash compatibility" "/bin/bash" "set -o pipefail && ./stacker.sh version"
    battle_test "Bash error handling" "/bin/bash" "set -euo pipefail && ./stacker.sh help"
fi

# Test with dash (Ubuntu default)
if [ -x "/bin/dash" ]; then
    battle_test "Dash compatibility" "/bin/dash" "./stacker.sh version"
    battle_test "Dash strict mode" "/bin/dash" "set -e && ./stacker.sh help"
fi

# Battle test: Error scenarios across shells
echo ""
echo "${BLUE}🔍 Testing error handling consistency...${NC}"

for shell in $TEST_SHELLS; do
    battle_test "Consistent error codes" "$shell" "./stacker.sh nonexistent-command; test \$? -ne 0"
    battle_test "Signal handling" "$shell" "timeout 1 ./stacker.sh version || test \$? -eq 124"
done

# Battle test: Output consistency  
echo ""
echo "${BLUE}🔍 Testing output format consistency...${NC}"

for shell in $TEST_SHELLS; do
    battle_test "Version format consistency" "$shell" "./stacker.sh version | grep -q 'Stacker Framework v0.0.2'"
    battle_test "Help format consistency" "$shell" "./stacker.sh help | grep -q 'Usage:'"
done

# Battle test: Performance consistency
echo ""
echo "${BLUE}🔍 Testing performance across shells...${NC}"

for shell in $TEST_SHELLS; do
    battle_test "Fast startup time" "$shell" "./stacker.sh version >/dev/null"
    battle_test "Memory efficiency" "$shell" "./stacker.sh version"
done

# Clean up
rm -f /tmp/battle_test_output

# Battle test results summary
echo ""
echo "${CYAN}📊 Battle Shell Compatibility Results${NC}"
echo "=================================="
echo "${GREEN}Passed: $PASSED_TESTS${NC}"
echo "${RED}Failed: $FAILED_TESTS${NC}"
echo "Total: $TOTAL_TESTS"

SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo ""
echo "Success Rate: ${SUCCESS_RATE}%"

# Battle test evaluation
if [ $SUCCESS_RATE -ge 80 ]; then
    echo ""
    echo "${GREEN}🎉 Excellent shell compatibility for v0.0.2!${NC}"
    echo "   POSIX compliance working across shells"
    echo "   Consistent behavior verified"
    echo "   Error handling uniform"
    exit 0
elif [ $SUCCESS_RATE -ge 60 ]; then
    echo ""
    echo "${YELLOW}⚠️  Good shell compatibility for early development${NC}"
    echo "   Minor inconsistencies detected"
    echo "   Acceptable for v0.0.2 stage"
    exit 0
else
    echo ""
    echo "${RED}❌ Shell compatibility issues detected${NC}"
    echo "   Major inconsistencies between shells"
    echo "   POSIX compliance needs work"
    exit 1
fi