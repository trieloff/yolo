#!/usr/bin/env bash

# Test script for flag mapping functionality

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

# Test that yolo exists and is executable
test_yolo_exists() {
    info "Testing yolo executable exists..."
    if [ -x "$YOLO_BIN" ]; then
        pass "yolo is executable"
    else
        fail "yolo is not executable at $YOLO_BIN"
    fi
}

# Test help output
test_help() {
    info "Testing help output..."
    if "$YOLO_BIN" --help >/dev/null 2>&1; then
        pass "Help command works"
    else
        fail "Help command failed"
    fi
}

# Test version output
test_version() {
    info "Testing version output..."
    if "$YOLO_BIN" --version >/dev/null 2>&1; then
        pass "Version command works"
    else
        fail "Version command failed"
    fi
}

# Test that missing arguments produce error
test_missing_args() {
    info "Testing missing arguments..."
    if "$YOLO_BIN" 2>/dev/null; then
        fail "Should fail with no arguments"
    else
        pass "Correctly fails with no arguments"
    fi
}

# Test dry-run with each agent
test_agent_flags() {
    local agent="$1"
    local expected="$2"
    
    info "Testing $agent flags..."
    local output
    output=$("$YOLO_BIN" --dry-run "$agent" echo "test" 2>&1 || true)
    
    if [[ "$output" == *"$expected"* ]]; then
        pass "$agent uses correct flags: $expected"
    else
        fail "$agent should use $expected, got: $output"
    fi
}

# Test environment variable override
test_env_override() {
    info "Testing environment variable override..."
    
    local output
    output=$(YOLO_FLAGS_claude="--custom-flag" "$YOLO_BIN" --dry-run claude echo "test" 2>&1 || true)
    
    if [[ "$output" == *"--custom-flag"* ]]; then
        pass "Environment override works for claude"
    else
        fail "Environment override failed, got: $output"
    fi
}

# Run all tests
main() {
    echo "========================================="
    echo "       YOLO Flag Mapping Tests"
    echo "========================================="
    echo
    
    test_yolo_exists
    test_help
    test_version
    test_missing_args
    
    echo
    echo "Testing agent flag mappings..."
    echo "---"
    
    test_agent_flags "codex" "--dangerously-bypass-approvals-and-sandbox"
    test_agent_flags "claude" "--dangerously-skip-permissions"
    test_agent_flags "copilot" "--allow-all-tools"
    test_agent_flags "droid" "--skip-permissions-unsafe"
    test_agent_flags "amp" "--dangerously-allow-all"
    test_agent_flags "cursor-agent" "--force"
    test_agent_flags "unknown-agent" "--yolo"
    
    echo
    test_env_override
    
    echo
    echo "========================================="
    echo "Results: ${GREEN}$pass_count passed${NC}, ${RED}$fail_count failed${NC}"
    echo "========================================="
    
    if [ "$fail_count" -gt 0 ]; then
        exit 1
    fi
}

main "$@"
