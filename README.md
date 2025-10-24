# 🎯 YOLO: The AI Agent Command Wrapper You Actually Need

![yolo-banner](https://placehold.co/800x200/1a1a2e/eaeaea?text=YOLO+-+AI+Agent+Wrapper&font=raleway)

## The Problem

You work with multiple AI coding agents—Claude, Copilot, Amp, Droid, Cursor, and others. Each one has different bypass flags for safety checks:

- Claude needs `--dangerously-skip-permissions`
- Amp wants `--dangerously-allow-all`  
- Copilot requires `--allow-all-tools --allow-all-paths`
- Cursor-agent uses `--force`

You're constantly forgetting which flag goes with which agent. And when you want to isolate AI changes in git worktrees, you're manually creating branches and directories every time.

## The Solution

**YOLO** is a simple, portable bash wrapper that:

✅ **Remembers the bypass flags for you** - Just type `yolo claude <command>` and it adds the right flags  
✅ **Creates git worktrees automatically** - Use `-w` to isolate AI work in `.conductor/` directories  
✅ **Works everywhere** - Pure bash, no dependencies, runs on macOS and Linux  
✅ **Stays out of your way** - Transparent wrapper that just works

## 🚀 Quick Start

### Installation

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/trieloff/yolo/main/install.sh | sh

# Or clone and install locally
git clone https://github.com/trieloff/yolo.git
cd yolo
./install.sh
```

The installer puts `yolo` in `~/.local/bin` and adds it to your PATH.

### Basic Usage

```bash
# Run Claude with proper bypass flags
yolo claude "create a PR for the new authentication feature"

# Run Amp with its flags
yolo amp "edit src/main.js to add error handling"

# Run any agent in an isolated git worktree
yolo -w claude "refactor the user service"
```

## 📖 How It Works

### Bypass Flag Mapping

Each agent gets its appropriate bypass flags automatically:

| Agent | Flags Added |
|-------|-------------|
| `codex` | `--dangerously-bypass-approvals-and-sandbox` |
| `claude` | `--dangerously-skip-permissions` |
| `copilot` | `--allow-all-tools --allow-all-paths` |
| `droid` | `--skip-permissions-unsafe` |
| `amp` | `--dangerously-allow-all` |
| `cursor-agent` | `--force` |
| *other* | `--yolo` |

### Worktree Mode

When you use `-w` or `--worktree`, yolo:

1. Creates `.conductor/<agent>-<timestamp>` directory
2. Creates branch `yolo/<agent>/<timestamp>`  
3. Sets up a git worktree
4. Runs your command in that worktree

This keeps AI experiments isolated from your main branch.

## 🎮 Usage Examples

### Basic Agent Invocation

```bash
# Run Claude to create a PR
yolo claude "create a PR to fix the authentication bug"

# Run Amp to edit files  
yolo amp "edit src/app.js to add logging"

# Run Copilot with a deployment request
yolo copilot "deploy to staging"
```

### Worktree Mode

```bash
# Create isolated worktree for Claude
yolo -w claude "refactor the database layer"

# The worktree is at:
#   .conductor/claude-20241024-184358/
# On branch:
#   yolo/claude/20241024-184358

# After reviewing changes, you can:
# 1. Merge the changes if you're happy with them:
cd .conductor/claude-20241024-184358
git add .
git commit -m "Refactor database layer"
git checkout main
git merge yolo/claude/20241024-184358
git worktree remove .conductor/claude-20241024-184358
git branch -d yolo/claude/20241024-184358

# 2. Or discard the worktree if you don't want the changes:
git worktree remove --force .conductor/claude-20241024-184358
git branch -D yolo/claude/20241024-184358
```

### Dry Run Mode

```bash
# See what would be executed without running it
yolo --dry-run claude "create tests"
# Output:
# yolo: [dry-run] Would execute in .:
#   claude --dangerously-skip-permissions create tests

# With worktree:
yolo -w --dry-run amp "build the project"
# Output:
# yolo: Creating worktree at .conductor/amp-20241024-184501 with branch yolo/amp/20241024-184501
# yolo: [dry-run] Branch: yolo/amp/20241024-184501
# yolo: [dry-run] Worktree: .conductor/amp-20241024-184501
# yolo: [dry-run] Would execute in .conductor/amp-20241024-184501:
#   amp --dangerously-allow-all build the project
```

### Environment Variable Overrides

Override flags for any agent:

```bash
# Use custom flags for Claude
export YOLO_FLAGS_claude="--yolo --custom-flag"
yolo claude "test command"
# Runs: claude --yolo --custom-flag test command

# Override for cursor-agent
export YOLO_FLAGS_cursor_agent="--super-force"
yolo cursor-agent "run task"
# Runs: cursor-agent --super-force run task
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `YOLO_FLAGS_<agent>` | Override flags for specific agent | `YOLO_FLAGS_claude="--custom"` |

Note: Replace hyphens with underscores in agent names (e.g., `cursor-agent` → `YOLO_FLAGS_cursor_agent`).

### Installation Options

```bash
# Verbose install
VERBOSE=true ./install.sh

# Upgrade existing installation  
UPGRADE=true ./install.sh

# Uninstall
./install.sh --uninstall
```

## 🛠️ Requirements

- **Bash** - 3.2+ (macOS and Linux compatible)
- **Git** - Required for worktree functionality (optional otherwise)

No other dependencies. Pure bash.

## 📋 Command Reference

```
Usage: yolo [-w|--worktree] [--dry-run] <agent> [args...]

Options:
  -w, --worktree      Create and run in a new git worktree
  --dry-run           Print the command without executing
  -h, --help          Show help message
  --version           Show version

Agents:
  codex, claude, copilot, droid, amp, cursor-agent, or any custom agent

Examples:
  yolo claude "create a PR for bug fix"
  yolo -w amp "edit file.js"
  yolo --dry-run codex "build the project"
```

## 🧪 Testing

```bash
# Run all tests
./test_yolo.sh

# Test specific functionality
./test_flags.sh
./test_worktree.sh
```

## 🤝 Contributing

Contributions welcome! To add a new agent:

1. Edit `agent_flags()` function in `executable_yolo`
2. Add a case for your agent with its bypass flags
3. Update README.md with the new agent
4. Submit a PR

### Adding a New Agent

```bash
# In executable_yolo, add to agent_flags() function:
case "$agent" in
    # ... existing cases ...
    my-new-agent)
        echo "--my-special-flag --another-flag"
        ;;
    # ...
esac
```

## 🔗 Related Projects

This project is part of the AI-aligned development tools ecosystem:

- **[AI-Aligned-Git](https://github.com/trieloff/ai-aligned-git)** - Git wrapper that enforces safe AI commit practices
- **[AI-Aligned-GH](https://github.com/trieloff/ai-aligned-gh)** - GitHub CLI wrapper for proper AI attribution
- **[Vibe-Coded-Badge-Action](https://github.com/trieloff/vibe-coded-badge-action)** - Show what percentage of commits are AI-generated
- **[GH-Workflow-Peek](https://github.com/trieloff/gh-workflow-peek)** - Filter GitHub Actions logs intelligently

## 📜 License

Apache-2.0 License - See [LICENSE](LICENSE) file for details.

## 🙏 Credits

Created by [@trieloff](https://github.com/trieloff) to solve a simple problem: remembering which AI agent needs which bypass flags.

Inspired by the original Elvish shell `yolo` function, now made portable and shareable.

---

**YOLO**: You Only Live Once, but you can run your AI agents in isolated worktrees as many times as you want. 🚀
