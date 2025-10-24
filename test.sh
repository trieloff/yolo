#!/bin/bash

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
echo "other $@"' > mocks/other
chmod +x mocks/other

export PATH="$(pwd)/mocks:$PATH"

# Run tests
output=$(./executable_yolo codex test)
if [ "$output" != "codex --dangerously-bypass-approvals-and-sandbox test" ]; then
    echo "Test failed for codex"
    exit 1
fi

output=$(./executable_yolo claude test)
if [ "$output" != "claude --dangerously-skip-permissions test" ]; then
    echo "Test failed for claude"
    exit 1
fi

output=$(./executable_yolo copilot test)
if [ "$output" != "copilot --allow-all-tools --allow-all-paths test" ]; then
    echo "Test failed for copilot"
    exit 1
fi

output=$(./executable_yolo droid test)
if [ "$output" != "droid --skip-permissions-unsafe test" ]; then
    echo "Test failed for droid"
    exit 1
fi

output=$(./executable_yolo amp test)
if [ "$output" != "amp --dangerously-allow-all test" ]; then
    echo "Test failed for amp"
    exit 1
fi

output=$(./executable_yolo cursor-agent test)
if [ "$output" != "cursor-agent --force test" ]; then
    echo "Test failed for cursor-agent"
    exit 1
fi

output=$(./executable_yolo other test)
if [ "$output" != "other --yolo test" ]; then
    echo "Test failed for other"
    exit 1
fi

echo "All tests passed"