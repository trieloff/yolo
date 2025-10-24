# 🚀 YOLO - You Only Launch Once

![A dramatic cinematic image of a developer typing commands with confidence](https://img.shields.io/badge/AI-Aligned-brightgreen) ![License](https://img.shields.io/badge/license-Apache--2.0-blue)

A portable command-line tool that runs AI coding agents with appropriate bypass flags and optional git worktree isolation. Stop typing those long, dangerous flags manually - let YOLO do it for you!

## 🎯 The Problem

Every AI coding agent has different flags for bypassing safety checks:

```bash
# Who can remember all these?
codex --dangerously-bypass-approvals-and-sandbox "fix the bug"
claude --dangerously-skip-permissions "refactor this code"
copilot --allow-all-tools --allow-all-paths "add feature"
droid --skip-permissions-unsafe "update tests"
amp --dangerously-allow-all "optimize performance"
```

And what if you want to work in an isolated git worktree to avoid messing up your main branch? Even more typing!

## 💡 The Solution

YOLO makes it simple - just prefix your command with `yolo`:

```bash
yolo claude "fix the bug"
yolo droid "refactor this code"
yolo -w copilot "add feature in a worktree"
```

That's it! YOLO automatically:
- 🎯 Maps each AI agent to its appropriate bypass flags
- 🌳 Creates git worktrees on demand (`-w` flag)
- 🔄 Works with any AI coding agent (adds `--yolo` for unknown ones)
- 🛡️ Keeps you safe by isolating work in worktrees

## 🚀 Quick Install

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/trieloff/yolo/main/install.sh | sh
```

### Manual Install

```bash
git clone https://github.com/trieloff/yolo.git
cd yolo
./install.sh
```

### Add to PATH

The installer will guide you, but typically:

```bash
# For bash/zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# For fish
echo 'set -gx PATH $HOME/.local/bin $PATH' >> ~/.config/fish/config.fish

# For elvish
echo 'set paths = [$HOME/.local/bin $@paths]' >> ~/.config/elvish/rc.elv
```

## 📖 Usage

### Basic Usage

```bash
yolo <command> [arguments...]
```

### With Worktree (Recommended for Agents)

```bash
yolo -w <command> [arguments...]
```

This creates a git worktree in `.conductor/<command>-<timestamp>` and runs the agent there.

### Examples

```bash
# Run Claude without worktree
yolo claude "Fix the authentication bug in src/auth.js"

# Run Droid in an isolated worktree
yolo -w droid "Refactor the entire authentication module"

# Run Cursor Agent with worktree
yolo -w cursor-agent "Add comprehensive tests"

# Run any other agent (adds --yolo flag)
yolo my-custom-agent "do something"
```

## 🤖 Supported AI Agents

| Agent | Flag Added | Command |
|-------|-----------|---------|
| Codex (Anthropic) | `--dangerously-bypass-approvals-and-sandbox` | `yolo codex` |
| Claude Code | `--dangerously-skip-permissions` | `yolo claude` |
| GitHub Copilot | `--allow-all-tools --allow-all-paths` | `yolo copilot` |
| Droid (Factory AI) | `--skip-permissions-unsafe` | `yolo droid` |
| Amp (Sourcegraph) | `--dangerously-allow-all` | `yolo amp` |
| Cursor Agent | `--force` | `yolo cursor-agent` |
| Other | `--yolo` | `yolo <command>` |

## 🌳 Git Worktree Feature

The `-w` or `--worktree` flag is a game-changer for AI-assisted development:

### What It Does

1. Creates a new git branch: `yolo/<agent>/<timestamp>`
2. Creates a worktree in `.conductor/<agent>-<timestamp>`
3. Changes to that worktree
4. Runs your AI agent there

### Why It's Awesome

- 🔒 **Isolation**: AI changes don't affect your main branch
- 🔄 **Easy Review**: Review changes before merging
- 🗑️ **Easy Cleanup**: Just delete the worktree if you don't like the changes
- 📊 **Parallel Work**: Run multiple agents simultaneously in different worktrees

### Example Workflow

```bash
# Start work in a worktree
cd my-project
yolo -w droid "Add comprehensive error handling"

# You're now in .conductor/droid-20251024-184528/
# The agent makes changes...

# Review the changes
git diff main

# If you like them, merge to main
git checkout main
git merge yolo/droid/20251024-184528

# Or discard them
git checkout main
git worktree remove .conductor/droid-20251024-184528
git branch -D yolo/droid/20251024-184528
```

## ⚙️ Configuration

No configuration needed! YOLO works out of the box.

### Environment Variables

You can override behavior with environment variables:

```bash
# Example: If an agent has a different command name
YOLO_CLAUDE_CMD=claude-beta yolo claude "test"
```

## 🔒 Safety

While YOLO adds bypass flags, remember:

- ⚠️ These flags bypass safety checks for a reason
- 🔍 Always review AI-generated changes before committing
- 🌳 Use `-w` flag to isolate changes in worktrees
- 👥 Use [ai-aligned-git](https://github.com/trieloff/ai-aligned-git) for proper commit attribution

## 🧪 Testing

Run the test suite:

```bash
./test.sh
```

Tests verify:
- Command-line argument parsing
- Flag mapping for each agent
- Worktree creation logic
- Error handling

## 🤝 Contributing

Contributions welcome! To add a new AI agent:

1. Edit `executable_yolo`
2. Add a new case in the command mapping section
3. Update the README
4. Add tests
5. Submit a PR

## 🔗 The Vibe Coding Ecosystem

This tool is part of the AI-aligned development toolkit:

- **[AI-Aligned-Git](https://github.com/trieloff/ai-aligned-git)** - Git wrapper that enforces safe AI commit practices
- **[AI-Aligned-GH](https://github.com/trieloff/ai-aligned-gh)** - GitHub CLI wrapper for proper AI attribution
- **[Vibe-Coded-Badge-Action](https://github.com/trieloff/vibe-coded-badge-action)** - Show what percentage of your code is AI-generated
- **[GH-Workflow-Peek](https://github.com/trieloff/gh-workflow-peek)** - Better GitHub Actions log filtering

## 📜 License

Apache-2.0 - See [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

Inspired by the original Elvish `yolo` function and follows the design philosophy of the AI-aligned toolkit.

---

*"Move fast and... actually, just move fast. We'll deal with the consequences in a worktree."*
