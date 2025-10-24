#!/bin/bash

set -euo pipefail

# Test script for YOLO

# Mock commands
mkdir -p mocks

echo '#!/bin/bash
echo "codex $@"' > mocks/codex
chmod +x mocks/codex

echo '#!/bin/bash
echo "claude $@"' > mocks/claude
chmod +x mocks/claude

echo '#!/bin/bash
echo "copilot $@"' > mocks/copilot
chmod +x mocks/copilot

echo '#!/bin/bash
echo "droid $@"' > mocks/droid
chmod +x mocks/droid

echo '#!/bin/bash
echo "amp $@"' > mocks/amp
chmod +x mocks/amp

echo '#!/bin/bash
echo "cursor-agent $@"' > mocks/cursor-agent
chmod +x mocks/cursor-agent

echo '#!/bin/bash
echo "opencode $@"' > mocks/opencode
chmod +x mocks/opencode

echo '#!/bin/bash
echo "other $@"' > mocks/other
chmod +x mocks/other

export PATH="$(pwd)/mocks:$PATH"

# Run tests
output=""
output=$(./executable_yolo --version)
if [ "$output" != "0.1.0" ]; then
    echo "Test failed for --version"
    exit 1
fi

output=""
output=$(./executable_yolo --dry-run codex test)
if [ "$output" != "codex --dangerously-bypass-approvals-and-sandbox test" ]; then
    echo "Test failed for --dry-run codex"
    exit 1
fi

output=""
output=$(./executable_yolo codex test)
if [ "$output" != "codex --dangerously-bypass-approvals-and-sandbox test" ]; then
    echo "Test failed for codex"
    exit 1
fi

output=""
output=$(./executable_yolo claude test)
if [ "$output" != "claude --dangerously-skip-permissions test" ]; then
    echo "Test failed for claude"
    exit 1
fi

export YOLO_FLAGS_claude="--custom-flag"
output=""
output=$(./executable_yolo claude test)
if [ "$output" != "claude --custom-flag test" ]; then
    echo "Test failed for YOLO_FLAGS_claude"
    exit 1
fi
unset YOLO_FLAGS_claude

export YOLO_FLAGS_cursor_agent="--custom-flag"
output=""
output=$(./executable_yolo cursor-agent test)
if [ "$output" != "cursor-agent --custom-flag test" ]; then
    echo "Test failed for YOLO_FLAGS_cursor_agent"
    exit 1
fi
unset YOLO_FLAGS_cursor_agent

output=""
output=$(./executable_yolo copilot test)
if [ "$output" != "copilot --allow-all-tools --allow-all-paths test" ]; then
    echo "Test failed for copilot"
    exit 1
fi

output=""
output=$(./executable_yolo droid test)
if [ "$output" != "droid --skip-permissions-unsafe test" ]; then
    echo "Test failed for droid"
    exit 1
fi

output=""
output=$(./executable_yolo amp test)
if [ "$output" != "amp --dangerously-allow-all test" ]; then
    echo "Test failed for amp"
    exit 1
fi

output=""
output=$(./executable_yolo cursor-agent test)
if [ "$output" != "cursor-agent --force test" ]; then
    echo "Test failed for cursor-agent"
    exit 1
fi

output=""
output=$(./executable_yolo opencode test)
if [ "$output" != "opencode test" ]; then
    echo "Test failed for opencode"
    exit 1
fi

output=""
output=$(./executable_yolo other test)
if [ "$output" != "other --yolo test" ]; then
    echo "Test failed for other"
    exit 1
fi

# Test worktree
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git init
fi

WORKTREE_PATH=$(./executable_yolo -w other test | cut -d ' ' -f 3)

if [ ! -d "$WORKTREE_PATH" ]; then
    echo "Test failed for worktree creation"
    exit 1
fi

cd "$WORKTREE_PATH"

output=$(../executable_yolo other test)

if [ "$output" != "other --yolo test" ]; then
    echo "Test failed for worktree command"
    exit 1
fi

cd ..

git worktree remove "$WORKTREE_PATH"
git worktree prune

# Test command not found
output=""
output=$(./executable_yolo notfound 2>&1)
if [[ "$output" != *"Warning: command not found: notfound"* ]]; then
    echo "Test failed for command not found"
    exit 1
fi

# Test YOLO_DEBUG
output=""
output=$(YOLO_DEBUG=true ./executable_yolo other test 2>&1)
if [[ "$output" != *"Executing: other --yolo test"* ]]; then
    echo "Test failed for YOLO_DEBUG"
    exit 1
fi

echo "All tests passed"
