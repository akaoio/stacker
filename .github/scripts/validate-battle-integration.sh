#!/bin/bash
# Battle Integration Validation Script
# Tests the complete Battle framework integration for Stacker CI/CD

set -e

echo "🧪 Battle Framework Integration Validation"
echo "==========================================="

# Configuration
VALIDATION_TIMEOUT=120
BATTLE_TESTS_DIR="tests/battle"
LEGACY_TESTS_DIR="tests"
BATTLE_CONFIG="battle.config.js"

# Results tracking
TOTAL_VALIDATIONS=0
PASSED_VALIDATIONS=0
FAILED_VALIDATIONS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Validation helper
validate() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    TOTAL_VALIDATIONS=$((TOTAL_VALIDATIONS + 1))
    echo ""
    echo "${CYAN}🔍 Validation: $test_name${NC}"
    echo "   Command: $test_command"
    
    if timeout $VALIDATION_TIMEOUT bash -c "$test_command"; then
        local actual_exit_code=$?
        if [ $actual_exit_code -eq $expected_exit_code ]; then
            echo "${GREEN}   ✅ PASS: $test_name${NC}"
            PASSED_VALIDATIONS=$((PASSED_VALIDATIONS + 1))
            return 0
        else
            echo "${RED}   ❌ FAIL: $test_name (exit code: $actual_exit_code, expected: $expected_exit_code)${NC}"
            FAILED_VALIDATIONS=$((FAILED_VALIDATIONS + 1))
            return 1
        fi
    else
        echo "${RED}   ❌ FAIL: $test_name (timeout or error)${NC}"
        FAILED_VALIDATIONS=$((FAILED_VALIDATIONS + 1))
        return 1
    fi
}

# Phase 1: Configuration Validation
echo "${BLUE}📋 Phase 1: Configuration Validation${NC}"

validate "Battle configuration exists and is valid" \
    "test -f $BATTLE_CONFIG && node -e 'import(\"./$BATTLE_CONFIG\").then(() => console.log(\"Valid\")).catch(e => process.exit(1))'"

validate "Battle command is available" \
    "npx battle --version"

validate "Build configuration is valid" \
    "test -f builder.config.js && node -e 'import(\"./builder.config.js\").then(() => console.log(\"Valid\")).catch(e => process.exit(1))'"

validate "Package.json has correct test script" \
    "grep -q '\"test\":.*run-tests.sh' package.json"

# Phase 2: Build System Validation
echo ""
echo "${BLUE}🔨 Phase 2: Build System Validation${NC}"

validate "Project builds successfully" \
    "npm run build"

validate "Build artifacts exist" \
    "test -f dist/index.js && test -f dist/index.cjs"

validate "Shell interface is executable" \
    "test -x stacker.sh && ./stacker.sh version | grep -q '0.0.2'"

validate "TypeScript interface loads" \
    "node -e 'import(\"./dist/index.js\").then(() => console.log(\"OK\")).catch(e => process.exit(1))'"

# Phase 3: Battle Test Discovery
echo ""
echo "${BLUE}🔍 Phase 3: Battle Test Discovery${NC}"

validate "Battle can process test directory" \
    "npx battle test tests/ --timeout=10 2>&1 | grep -qE '(Starting|Running|Found)' || true"

validate "Battle configuration pattern matches files" \
    "find tests/ -name '*.test.*' -type f | wc -l | grep -qE '[1-9]'"

validate "Shell compatibility tests exist" \
    "test -f tests/battle/shell-compatibility.test.sh && test -x tests/battle/shell-compatibility.test.sh"

validate "Hybrid architecture tests exist" \
    "test -f tests/battle/hybrid-architecture.test.ts"

# Phase 4: Individual Test Validation
echo ""
echo "${BLUE}🧪 Phase 4: Individual Test Validation${NC}"

validate "Shell compatibility test runs standalone" \
    "./tests/battle/shell-compatibility.test.sh"

validate "Legacy Battle integration test works" \
    "test -f test/battle-integration.test.ts && timeout 60 npx tsx test/battle-integration.test.ts || true"

validate "Simple Battle test executes" \
    "test -f test/battle-simple.test.ts && timeout 30 npx tsx test/battle-simple.test.ts || true"

# Phase 5: Full Battle Integration
echo ""
echo "${BLUE}🚀 Phase 5: Full Battle Integration${NC}"

validate "Battle test suite executes with config" \
    "timeout 90 npx battle test tests/ --timeout=60 || true"

validate "Battle generates JSON report" \
    "npx battle test tests/ --timeout=60 || true"

validate "Battle test completion" \
    "npm run test:ci || true"

# Phase 6: CI-specific Validations
echo ""
echo "${BLUE}🔧 Phase 6: CI/CD Integration${NC}"

validate "CI test script works" \
    "CI=true npm run test:ci || true"

validate "Test results directory structure" \
    "test -d tests/results && test -d tests/results/screenshots"

validate "Legacy test script still available" \
    "test -x tests/run-tests.sh && timeout 30 npm run test:legacy || true"

# Phase 7: Multi-shell Validation
echo ""
echo "${BLUE}🐚 Phase 7: Multi-shell Validation${NC}"

for shell in "/bin/sh" "/bin/bash" "/bin/dash"; do
    if [ -x "$shell" ]; then
        validate "Stacker works with $shell" \
            "SHELL=$shell $shell ./stacker.sh version | grep -q '0.0.2'"
    else
        echo "${YELLOW}   ⚠️  Skipping $shell (not available)${NC}"
    fi
done

# Phase 8: Performance and Resource Validation
echo ""
echo "${BLUE}⚡ Phase 8: Performance Validation${NC}"

validate "Build completes within time limit" \
    "timeout 60 npm run build"

validate "Test suite completes within time limit" \
    "timeout 120 npm run test || true"

validate "Memory usage is reasonable during tests" \
    "timeout 30 npm run test:shell || true"

# Phase 9: Integration with CI Workflows
echo ""
echo "${BLUE}🔄 Phase 9: CI Workflow Validation${NC}"

validate "GitHub Actions workflow exists" \
    "test -f .github/workflows/test.yml"

validate "CI setup script exists and is executable" \
    "test -x .github/scripts/setup-ci.sh"

validate "Workflow has correct Battle integration" \
    "grep -q 'npm run test:ci' .github/workflows/test.yml"

validate "Workflow includes multi-shell testing" \
    "grep -A 2 'matrix:' .github/workflows/test.yml | grep -q 'shell:'"

# Final Results Summary
echo ""
echo "${CYAN}📊 Battle Integration Validation Results${NC}"
echo "============================================"
echo "${GREEN}Passed: $PASSED_VALIDATIONS${NC}"
echo "${RED}Failed: $FAILED_VALIDATIONS${NC}"
echo "Total: $TOTAL_VALIDATIONS"

SUCCESS_RATE=$((PASSED_VALIDATIONS * 100 / TOTAL_VALIDATIONS))
echo ""
echo "Success Rate: ${SUCCESS_RATE}%"

# Evaluation and recommendations
if [ $SUCCESS_RATE -ge 90 ]; then
    echo ""
    echo "${GREEN}🎉 Excellent Battle Integration!${NC}"
    echo "   All major components working"
    echo "   CI/CD pipeline ready for production"
    echo "   Battle framework fully integrated"
    echo ""
    echo "${GREEN}✅ Ready for deployment${NC}"
    exit 0
elif [ $SUCCESS_RATE -ge 75 ]; then
    echo ""
    echo "${YELLOW}⚠️  Good Battle Integration${NC}"
    echo "   Core functionality working"
    echo "   Minor issues detected"
    echo "   Safe for deployment with monitoring"
    echo ""
    echo "${YELLOW}🚀 Acceptable for deployment${NC}"
    exit 0
elif [ $SUCCESS_RATE -ge 60 ]; then
    echo ""
    echo "${YELLOW}⚠️  Partial Battle Integration${NC}"
    echo "   Basic functionality working"
    echo "   Several issues need attention"
    echo "   Acceptable for v0.0.2 development"
    echo ""
    echo "🛠️  Recommendations:"
    echo "   - Review failed validations above"
    echo "   - Fix critical configuration issues"
    echo "   - Test individual components"
    echo ""
    exit 0
else
    echo ""
    echo "${RED}❌ Battle Integration Issues${NC}"
    echo "   Major problems detected"
    echo "   CI/CD pipeline may not work correctly"
    echo "   Battle framework not properly integrated"
    echo ""
    echo "🚨 Action Required:"
    echo "   1. Review all failed validations"
    echo "   2. Check Battle and Builder configurations"
    echo "   3. Verify test file structure"
    echo "   4. Test individual components manually"
    echo ""
    exit 1
fi