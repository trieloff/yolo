#!/bin/bash

# Test script for YOLO
# Validates basic functionality without requiring actual AI tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    printf "${BLUE}[TEST]${NC} %s\n" "$*"
}

print_pass() {
    printf "${GREEN}[PASS]${NC} %s\n" "$*"
}

print_fail() {
    printf "${RED}[FAIL]${NC} %s\n" "$*"
}

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

run_test() {
    local test_name="$1"
    shift
    TESTS_RUN=$((TESTS_RUN + 1))
    print_test "$test_name"
    if "$@"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        print_pass "$test_name"
        return 0
    else
        print_fail "$test_name"
        return 1
    fi
}

# Use local executable for testing (more reliable in CI)
if [ -x "./executable_yolo" ]; then
    echo "Using local executable for testing"
    YOLO_CMD="$(pwd)/executable_yolo"
elif command -v yolo >/dev/null 2>&1; then
    YOLO_CMD="yolo"
else
    echo "Error: executable_yolo not found and yolo command not in PATH"
    exit 1
fi

echo "Testing YOLO command..."
echo

# Test 1: Help flag
test_help() {
    $YOLO_CMD --help >/dev/null 2>&1
}
run_test "Help flag works" test_help

# Test 2: Missing command error
test_missing_command() {
    ! $YOLO_CMD 2>/dev/null
}
run_test "Missing command shows error" test_missing_command

# Test 3: Create a mock command for testing
mkdir -p /tmp/yolo-test
cat > /tmp/yolo-test/mock-agent <<'EOF'
#!/bin/bash
# Mock AI agent for testing
echo "Mock agent called with args: $*"
# Check if --yolo flag was passed
for arg in "$@"; do
    if [ "$arg" = "--yolo" ]; then
        exit 0
    fi
done
exit 1
EOF
chmod +x /tmp/yolo-test/mock-agent

# Test 4: Unknown command with --yolo flag
test_unknown_command() {
    export PATH="/tmp/yolo-test:$PATH"
    $YOLO_CMD mock-agent test-arg 2>&1 | grep -q "Running mock-agent with --yolo"
}
run_test "Unknown command gets --yolo flag" test_unknown_command

# Test 5: Verify known command mappings (just check the logic, don't execute)
test_command_mapping() {
    # Test that help shows all supported commands
    $YOLO_CMD --help 2>&1 | grep -q "codex" && \
    $YOLO_CMD --help 2>&1 | grep -q "claude" && \
    $YOLO_CMD --help 2>&1 | grep -q "droid" && \
    $YOLO_CMD --help 2>&1 | grep -q "amp" && \
    $YOLO_CMD --help 2>&1 | grep -q "copilot"
}
run_test "Command mappings documented in help" test_command_mapping

# Test 6: Verify opencode command is documented
test_opencode_mapping() {
    $YOLO_CMD --help 2>&1 | grep -q "opencode"
}
run_test "OpenCode command documented in help" test_opencode_mapping

# Test 7: Worktree flag parsing (without actually creating worktree)
test_worktree_flag() {
    # Test with non-git directory - should fail gracefully
    temp_test_dir=$(mktemp -d)
    cd "$temp_test_dir"
    # Strip ANSI color codes for reliable grepping
    output=$($YOLO_CMD -w mock-agent test 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    result=$?
    cd /tmp  # Go back to a safe directory
    rm -rf "$temp_test_dir"
    echo "$output" | grep -q "Error: not in a git repository"
    return $?
}
run_test "Worktree flag requires git repository" test_worktree_flag

# Test 8: Test in actual git repo
test_git_repo_check() {
    # Create a temporary git repo
    temp_repo=$(mktemp -d)
    cd "$temp_repo"
    git init >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > test.txt
    git add test.txt
    git commit -m "Initial commit" >/dev/null 2>&1

    # Test worktree creation
    export PATH="/tmp/yolo-test:$PATH"
    $YOLO_CMD -w mock-agent "test" 2>&1 | grep -q "Creating worktree"
    local result=$?

    # Cleanup
    cd /tmp
    rm -rf "$temp_repo"

    return "$result"
}
run_test "Worktree creation in git repo" test_git_repo_check

# Cleanup
rm -rf /tmp/yolo-test

echo
echo "================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"
echo "================================="

if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
    print_pass "All tests passed!"
    exit 0
else
    print_fail "Some tests failed"
    exit 1
fi