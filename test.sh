#!/usr/bin/env bash

# YOLO Test Suite
# Tests the yolo wrapper functionality
#
# Copyright 2025 Lars Trieloff
# Licensed under the Apache License, Version 2.0

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use local executable_yolo if it exists
if [[ -f "$SCRIPT_DIR/executable_yolo" ]]; then
    YOLO_CMD="$SCRIPT_DIR/executable_yolo"
else
    YOLO_CMD="yolo"
fi

print_test_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $*"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}✗ FAIL${NC}: $*"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $*"
}

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 1: Check if yolo command exists
test_yolo_exists() {
    print_test_header "Test 1: YOLO Command Exists"
    run_test

    if [[ -x "$YOLO_CMD" ]]; then
        print_pass "yolo command found at $YOLO_CMD"
    else
        print_fail "yolo command not found or not executable at $YOLO_CMD"
    fi
}

# Test 2: Test --help flag
test_help_flag() {
    print_test_header "Test 2: Help Flag"
    run_test

    if "$YOLO_CMD" --help >/dev/null 2>&1; then
        print_pass "yolo --help works"
    else
        print_fail "yolo --help failed"
    fi
}

# Test 3: Test --version flag
test_version_flag() {
    print_test_header "Test 3: Version Flag"
    run_test

    if "$YOLO_CMD" --version >/dev/null 2>&1; then
        print_pass "yolo --version works"
    else
        print_fail "yolo --version failed"
    fi
}

# Test 4: Test error when no command provided
test_no_command_error() {
    print_test_header "Test 4: Error When No Command"
    run_test

    if ! "$YOLO_CMD" 2>/dev/null; then
        print_pass "yolo correctly errors when no command provided"
    else
        print_fail "yolo should error when no command provided"
    fi
}

# Test 5: Test flag detection for each command
test_command_flags() {
    print_test_header "Test 5: Command Flag Detection"

    local commands=(
        "codex:--dangerously-bypass-approvals-and-sandbox"
        "claude:--dangerously-skip-permissions"
        "copilot:--allow-all-tools"
        "droid:--skip-permissions-unsafe"
        "amp:--dangerously-allow-all"
        "cursor-agent:--force"
        "unknown-tool:--yolo"
    )

    for cmd_pair in "${commands[@]}"; do
        run_test
        local cmd="${cmd_pair%%:*}"
        local expected_flag="${cmd_pair##*:}"

        # Create a dummy command that just echoes its arguments
        local test_script="/tmp/test_yolo_$cmd"
        cat > "$test_script" << 'EOF'
#!/bin/bash
echo "$@"
EOF
        chmod +x "$test_script"

        # Use PATH to make the test command available
        local output
        if output=$(PATH="/tmp:$PATH" YOLO_DEBUG=true "$YOLO_CMD" "$cmd" "test-arg" 2>&1); then
            if echo "$output" | grep -q "$expected_flag"; then
                print_pass "yolo $cmd includes $expected_flag"
            else
                print_fail "yolo $cmd should include $expected_flag (got: $output)"
            fi
        else
            # Command not found is OK for this test
            print_info "Skipping flag test for $cmd (command not found)"
        fi

        rm -f "$test_script"
    done
}

# Test 6: Test worktree creation (if in a git repo)
test_worktree_creation() {
    print_test_header "Test 6: Worktree Creation"

    # Create a temporary git repository for testing
    local test_repo="/tmp/yolo_test_repo_$$"
    mkdir -p "$test_repo"
    cd "$test_repo"

    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create an initial commit
    echo "test" > README.md
    git add README.md
    git commit -q -m "Initial commit"

    run_test

    # Create a dummy echo command
    local echo_cmd="/tmp/test_yolo_echo"
    cat > "$echo_cmd" << 'EOF'
#!/bin/bash
echo "Running in: $PWD"
echo "Args: $@"
EOF
    chmod +x "$echo_cmd"

    # Test worktree creation
    local output
    if output=$(PATH="/tmp:$PATH" "$YOLO_CMD" -w echo "test" 2>&1); then
        if [[ -d "$test_repo/.conductor" ]]; then
            print_pass "Worktree directory .conductor created"

            # Check if worktree was created
            local worktree_count
            worktree_count=$(find "$test_repo/.conductor" -maxdepth 1 -type d -name "echo-*" | wc -l)
            if [[ $worktree_count -gt 0 ]]; then
                print_pass "Worktree subdirectory created in .conductor"
            else
                print_fail "No worktree subdirectory found in .conductor"
            fi
        else
            print_fail ".conductor directory not created"
        fi
    else
        print_fail "yolo -w failed: $output"
    fi

    # Cleanup
    cd /tmp
    rm -rf "$test_repo"
    rm -f "$echo_cmd"
}

# Test 7: Test worktree error when not in git repo
test_worktree_no_git_error() {
    print_test_header "Test 7: Worktree Error Outside Git Repo"
    run_test

    # Create a temporary non-git directory
    local test_dir="/tmp/yolo_test_nogit_$$"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create a dummy command
    local echo_cmd="/tmp/test_yolo_echo2"
    cat > "$echo_cmd" << 'EOF'
#!/bin/bash
echo "Should not run"
EOF
    chmod +x "$echo_cmd"

    # Test that worktree fails outside git repo
    if ! PATH="/tmp:$PATH" "$YOLO_CMD" -w echo "test" 2>/dev/null; then
        print_pass "yolo -w correctly errors outside git repository"
    else
        print_fail "yolo -w should error outside git repository"
    fi

    # Cleanup
    cd /tmp
    rm -rf "$test_dir"
    rm -f "$echo_cmd"
}

# Test 8: Test that original command arguments are preserved
test_argument_preservation() {
    print_test_header "Test 8: Argument Preservation"
    run_test

    # Create a test command that prints all arguments
    local test_cmd="/tmp/test_yolo_args"
    cat > "$test_cmd" << 'EOF'
#!/bin/bash
for arg in "$@"; do
    echo "ARG: $arg"
done
EOF
    chmod +x "$test_cmd"

    # Run yolo with multiple arguments
    local output
    if output=$(PATH="/tmp:$PATH" "$YOLO_CMD" test "arg1" "arg with spaces" "arg3" 2>&1); then
        if echo "$output" | grep -q "ARG: arg1" && \
           echo "$output" | grep -q "ARG: arg with spaces" && \
           echo "$output" | grep -q "ARG: arg3"; then
            print_pass "Command arguments preserved correctly"
        else
            print_fail "Command arguments not preserved (got: $output)"
        fi
    else
        print_fail "yolo test command failed"
    fi

    # Cleanup
    rm -f "$test_cmd"
}

# Print summary
print_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        echo ""
        return 1
    fi
}

# Main test runner
main() {
    echo ""
    echo -e "${BLUE}YOLO Test Suite${NC}"
    echo ""

    test_yolo_exists
    test_help_flag
    test_version_flag
    test_no_command_error
    test_command_flags
    test_worktree_creation
    test_worktree_no_git_error
    test_argument_preservation

    print_summary
}

# Run tests
main "$@"
