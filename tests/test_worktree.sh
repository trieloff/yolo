#!/usr/bin/env bash

# Test script for worktree functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YOLO_BIN="$SCRIPT_DIR/../executable_yolo"

pass_count=0
fail_count=0

# Test helper functions
pass() {
    printf "${GREEN}✓${NC} %s\n" "$1"
    ((pass_count++)) || true
}

fail() {
    printf "${RED}✗${NC} %s\n" "$1"
    ((fail_count++)) || true
}

info() {
    printf "${YELLOW}→${NC} %s\n" "$1"
}

# Create a temporary git repository for testing
setup_test_repo() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    
    cd "$tmp_dir"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    echo "test" > README.md
    git add README.md
    git commit -q -m "Initial commit"
    
    echo "$tmp_dir"
}

# Clean up test repository
cleanup_test_repo() {
    local repo_dir="$1"
    if [ -d "$repo_dir" ]; then
        cd /
        rm -rf "$repo_dir"
    fi
}

# Test worktree creation with dry-run
test_worktree_dry_run() {
    info "Testing worktree dry-run..."
    
    local test_repo
    test_repo=$(setup_test_repo)
    
    local output
    output=$("$YOLO_BIN" -w --dry-run claude echo "test" 2>&1 || true)
    
    if echo "$output" | grep -q "yolo/claude/"; then
        pass "Dry-run shows correct branch pattern"
    else
        fail "Dry-run branch pattern incorrect: $output"
    fi
    
    if echo "$output" | grep -q ".conductor/claude-"; then
        pass "Dry-run shows correct worktree path"
    else
        fail "Dry-run worktree path incorrect: $output"
    fi
    
    cleanup_test_repo "$test_repo"
}

# Test actual worktree creation
test_worktree_creation() {
    info "Testing actual worktree creation..."
    
    local test_repo
    test_repo=$(setup_test_repo)
    
    # Change to test repo directory
    cd "$test_repo" || {
        fail "Could not cd to test repo"
        return
    }
    
    # Run yolo with worktree to create a directory and check it exists
    # Use 'echo' as the agent command (which exists on all systems)
    local agent="echo"
    if "$YOLO_BIN" -w "$agent" "success" >/dev/null 2>&1; then
        pass "Worktree command executed successfully"
    else
        fail "Worktree command failed"
        cleanup_test_repo "$test_repo"
        return
    fi
    
    # Change back to test repo (yolo -w changes directory to the worktree)
    cd "$test_repo" || {
        fail "Could not cd back to test repo"
        cleanup_test_repo "$test_repo"
        return
    }
    
    # Check that .conductor directory was created
    if [ -d "$test_repo/.conductor" ]; then
        pass ".conductor directory created"
    else
        fail ".conductor directory not found"
    fi
    
    # Check that a worktree directory exists
    local worktree_count
    worktree_count=$(find "$test_repo/.conductor" -maxdepth 1 -type d -name "${agent}-*" 2>/dev/null | wc -l)
    
    if [ "$worktree_count" -gt 0 ]; then
        pass "Worktree directory created in .conductor"
    else
        fail "No worktree directory found in .conductor"
    fi
    
    # Check that the branch was created
    if git -C "$test_repo" branch --list | grep -q "yolo/${agent}/"; then
        pass "Branch created with correct pattern"
    else
        fail "Branch not created correctly"
    fi
    
    cleanup_test_repo "$test_repo"
}

# Test that worktree fails outside git repo
test_worktree_non_repo() {
    info "Testing worktree outside git repo..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if "$YOLO_BIN" -w claude echo "test" 2>/dev/null; then
        fail "Should fail outside git repo"
    else
        pass "Correctly fails outside git repo"
    fi
    
    cd /
    rm -rf "$tmp_dir"
}

# Run all tests
main() {
    echo "========================================="
    echo "       YOLO Worktree Tests"
    echo "========================================="
    echo
    
    # Check if git is available
    if ! command -v git >/dev/null 2>&1; then
        echo "Git not found - skipping worktree tests"
        exit 0
    fi
    
    test_worktree_dry_run
    test_worktree_creation
    test_worktree_non_repo
    
    echo
    echo "========================================="
    echo "Results: ${GREEN}$pass_count passed${NC}, ${RED}$fail_count failed${NC}"
    echo "========================================="
    
    if [ "$fail_count" -gt 0 ]; then
        exit 1
    fi
}

main "$@"
