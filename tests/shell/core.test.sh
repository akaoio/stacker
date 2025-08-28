#!/bin/sh
# Battle Test: Stacker Core Module (Shell)
# Tests core functionality of the Stacker shell framework

# Test configuration
TEST_NAME="Stacker Core Module"
TEST_VERSION="0.0.2"

echo "⚠️  Battle helpers not available - using minimal test framework"

# Minimal test framework for early development
test_assert() {
    local expected="$1"
    local actual="$2" 
    local description="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo "✅ $description"
        return 0
    else
        echo "❌ $description"
        echo "   Expected: $expected"
        echo "   Actual: $actual"
        return 1
    fi
}

test_start() {
    echo "🧪 Starting test: $1"
}

test_end() {
    echo "📊 Test completed: $1"
}

# Test setup
STACKER_DIR="../.."
STACKER_SCRIPT="$STACKER_DIR/stacker.sh"

test_start "$TEST_NAME v$TEST_VERSION"

# Test 1: Framework availability
echo "\n1️⃣  Testing framework availability..."
if [ -f "$STACKER_SCRIPT" ]; then
    test_assert "true" "true" "Stacker script exists"
else
    test_assert "true" "false" "Stacker script exists"
    exit 1
fi

# Test 2: Basic version check  
echo "\n2️⃣  Testing version information..."
VERSION_OUTPUT=$(cd "$STACKER_DIR" && ./stacker.sh version 2>/dev/null)
case "$VERSION_OUTPUT" in
    *"0.0.2"*) test_assert "true" "true" "Version shows 0.0.2 (honest development)" ;;
    *"2.0.0"*) test_assert "true" "false" "Version should be 0.0.2, not 2.0.0 (dishonest)" ;;
    *) test_assert "true" "false" "Version output contains expected version" ;;
esac

# Test 3: Help command
echo "\n3️⃣  Testing help system..."
HELP_OUTPUT=$(cd "$STACKER_DIR" && ./stacker.sh help 2>/dev/null)
case "$HELP_OUTPUT" in
    *"stacker"*) test_assert "true" "true" "Help output mentions stacker" ;;
    *) test_assert "true" "false" "Help output is accessible" ;;
esac

# Test 4: Module loading system
echo "\n4️⃣  Testing module loading..."
cd "$STACKER_DIR"
if ./stacker.sh help >/dev/null 2>&1; then
    test_assert "true" "true" "Core modules load without errors"
else
    test_assert "true" "false" "Core modules load without errors"
fi

# Test 5: POSIX compliance check
echo "\n5️⃣  Testing POSIX compliance..."
if command -v dash >/dev/null 2>&1; then
    if dash "$STACKER_SCRIPT" version >/dev/null 2>&1; then
        test_assert "true" "true" "POSIX compliant (works with dash)"
    else
        test_assert "true" "false" "POSIX compliant (works with dash)"
    fi
else
    echo "⚠️  dash not available - skipping POSIX compliance test"
fi

# Test 6: Error handling
echo "\n6️⃣  Testing error handling..."
cd "$STACKER_DIR"
ERROR_OUTPUT=$(./stacker.sh nonexistent-command 2>&1)
case "$ERROR_OUTPUT" in
    *"Unknown command"*|*"ERROR"*|*"error"*) 
        test_assert "true" "true" "Error handling works for invalid commands" 
        ;;
    *) 
        test_assert "true" "false" "Error handling works for invalid commands"
        ;;
esac

echo "\n📋 Test Summary for Stacker Core v$TEST_VERSION"
echo "   Framework: Universal POSIX Shell Framework"
echo "   Architecture: Hybrid Shell + TypeScript" 
echo "   Development State: Early (v0.0.2) - Honest versioning"

test_end "$TEST_NAME"
exit 0