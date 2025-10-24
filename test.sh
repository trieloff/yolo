#!/bin/bash

# Test script for YOLO
# Validates basic functionality without requiring actual AI tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if yolo is installed
YOLO_CMD="./executable_yolo"
if [ ! -x "$YOLO_CMD" ]; then
    # Fallback to system yolo if local not available
    if ! command -v yolo >/dev/null 2>&1; then
        echo "Error: yolo command not found"
        echo "Run from the yolo directory or install yolo to PATH"
        exit 1
    fi
    YOLO_CMD="yolo"
fi

echo "Testing YOLO command... (using $YOLO_CMD)"
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
    $YOLO_CMD --help 2>&1 | grep -q "copilot" && \
    $YOLO_CMD --help 2>&1 | grep -q "opencode"
}
run_test "Command mappings documented in help" test_command_mapping

# Test 6: Worktree flag parsing (without actually creating worktree)
test_worktree_flag() {
    local original_dir="$PWD"
    # Test with non-git directory - should fail gracefully
    cd /tmp
    # Strip ANSI color codes for reliable grepping
    output=$("$original_dir/$YOLO_CMD" -w mock-agent test 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    cd "$original_dir"
    echo "$output" | grep -q "not in a git repository"
    return $?
}
run_test "Worktree flag requires git repository" test_worktree_flag

# Test 7: Test in actual git repo
test_git_repo_check() {
    local original_dir="$PWD"
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
    "$original_dir/$YOLO_CMD" -w mock-agent "test" 2>&1 | grep -q "Creating worktree"
    local result=$?
    
    # Cleanup
    cd /tmp
    rm -rf "$temp_repo"
    cd "$original_dir"
    
    return $result
}
run_test "Worktree creation in git repo" test_git_repo_check

# Cleanup
rm -rf /tmp/yolo-test

echo
echo "================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $((TESTS_RUN - TESTS_PASSED))"
echo "================================"

if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
    print_pass "All tests passed!"
    exit 0
else
    print_fail "Some tests failed"
    exit 1
fi
