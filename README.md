# YOLO - AI CLI Tool Wrapper with Worktree Support

> "You Only Launch Once... but in an isolated git worktree!"

YOLO is a command-line wrapper for AI coding assistants that automatically adds the appropriate bypass/danger flags and optionally creates isolated git worktrees for agent sessions.

Part of the **AI-Aligned** toolchain:
- [ai-aligned-git](https://github.com/trieloff/ai-aligned-git) - Git wrapper for safe AI commit practices
- [ai-aligned-gh](https://github.com/trieloff/ai-aligned-gh) - GitHub CLI wrapper for proper AI attribution
- **yolo** - AI CLI launcher with worktree isolation (this project)
 - [vibe-coded-badge-action](https://github.com/trieloff/vibe-coded-badge-action) - Badge showing AI-generated code percentage
 - [gh-workflow-peek](https://github.com/trieloff/gh-workflow-peek) - Smarter GitHub Actions log filtering

## Features

- 🚀 **Quick Launch**: Simple wrapper to launch AI tools with one command
- 🎯 **Smart Flags**: Automatically adds appropriate bypass flags for each AI tool
- 🌳 **Worktree Isolation**: Optional `-w` flag creates isolated git worktrees
- 🔒 **Safe Experimentation**: Work in isolated environments without affecting main codebase
- 🧹 **Clean History**: Separate branches for each agent session with timestamps
- 🛠️ **Shell Agnostic**: Works in bash, zsh, fish, elvish, and more

## Why YOLO?

AI coding assistants often require various "bypass" or "danger" flags to operate without constant permission prompts. YOLO makes this easier by:

1. **Remembering the flags** - No need to memorize `--dangerously-skip-permissions` or `--allow-all-tools`
2. **Creating safe workspaces** - Use `-w` to experiment in isolated git worktrees
3. **Organizing experiments** - Each session gets its own timestamped branch in `.conductor/`

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/trieloff/yolo/main/install.sh | sh
```

### Manual Install

```bash
git clone https://github.com/trieloff/yolo.git
cd yolo
./install.sh
```

### What It Does

The installer:
1. Creates `~/.local/bin` directory (if needed)
2. Copies `executable_yolo` to `~/.local/bin/yolo`
3. Adds `~/.local/bin` to your PATH (if needed)
4. Makes the script executable

After installation, restart your shell or run:
```bash
source ~/.bashrc  # or ~/.zshrc, ~/.config/fish/config.fish, etc.
```

## Usage

### Basic Usage

```bash
# Launch Claude Code with --dangerously-skip-permissions
yolo claude

# Launch Codex with --dangerously-bypass-approvals-and-sandbox
yolo codex "implement feature X"

# Launch Copilot with --allow-all-tools --allow-all-paths
yolo copilot chat
```

### Worktree Mode

Create an isolated git worktree before launching the AI tool:

```bash
# Create worktree in .conductor/claude-20251024-183537
# with branch yolo/claude/20251024-183537
yolo -w claude "refactor the entire codebase"

# Work in isolation - changes are in the worktree
# Original code remains untouched
```

**What happens in worktree mode:**
1. Checks you're in a git repository
2. Creates `.conductor/` directory
3. Creates a new branch: `yolo/<command>/<timestamp>`
4. Creates worktree at `.conductor/<command>-<timestamp>`
5. Changes to the worktree directory
6. Launches the AI tool

### Supported Commands

| Command | Flags Added |
|---------|-------------|
| `codex` | `--dangerously-bypass-approvals-and-sandbox` |
| `claude` | `--dangerously-skip-permissions` |
| `copilot` | `--allow-all-tools --allow-all-paths` |
| `droid` | `--skip-permissions-unsafe` |
| `amp` | `--dangerously-allow-all` |
| `cursor-agent` | `--force` |
| `opencode` | *(no flags)* |
| *(other)* | `--yolo` |

### Examples

```bash
# Basic usage
yolo claude
yolo claude "fix all the bugs"
yolo codex --help

# Worktree mode
yolo -w claude
yolo --worktree codex "experimental refactoring"

# OpenCode (no extra flags added)
yolo opencode "build"
yolo -w opencode "run integration suite"

# Help and version
yolo --help
yolo --version

# Dry-run mode
yolo --dry-run claude "test changes"
yolo -n codex  # Short form

# Quick cleanup (from repository root)
git worktree remove .conductor/<agent>-<YYYYMMDD-HHMMSS>
git branch -D yolo/<agent>/<YYYYMMDD-HHMMSS>
```

## How It Works

### Flag Mapping

YOLO recognizes common AI CLI tools and adds the appropriate flags:

```bash
# You type:
yolo claude "implement feature"

# YOLO executes:
claude --dangerously-skip-permissions "implement feature"
```

### Worktree Creation

When you use `-w` or `--worktree`:

```bash
# You type:
yolo -w claude "big refactor"

# YOLO does:
# 1. Creates .conductor/ directory
# 2. Creates branch: yolo/claude/20251024-183537
# 3. Creates worktree: .conductor/claude-20251024-183537
# 4. cd to worktree
# 5. Runs: claude --dangerously-skip-permissions "big refactor"
```

## Worktree Benefits

### Safe Experimentation
```bash
# Main codebase stays pristine
yolo -w claude "try a radical refactor"

# If it works: merge the branch
# If it fails: just delete the worktree
```

### Parallel Sessions
```bash
# Terminal 1: Feature work
cd ~/project
yolo -w claude "add auth system"

# Terminal 2: Bug fixing (main codebase unaffected)
cd ~/project
yolo -w claude "fix the memory leak"
```

### Clean Separation
```
your-repo/
├── .conductor/
│   ├── claude-20251024-101530/   # Session 1
│   ├── claude-20251024-143022/   # Session 2
│   └── codex-20251024-160815/    # Session 3
└── (your main code)
```

### Cleaning Up Worktrees

After you're done with a worktree session, you can clean it up:

```bash
# Remove a specific worktree
git worktree remove .conductor/claude-20251024-183537

# Delete the associated branch
git branch -D yolo/claude/20251024-183537

# Or clean up all worktrees at once
rm -rf .conductor
git worktree prune

# List all worktrees to see what's active
git worktree list
```

**Tip**: Add `.conductor/` to your `.gitignore` to keep worktree directories out of your repository:

```bash
echo "/.conductor/" >> .gitignore
```

## Configuration

### Environment Variables

```bash
# Enable debug output
export YOLO_DEBUG=true
yolo claude

# Override flags for specific commands
export YOLO_FLAGS_claude="--custom-flag --another-flag"
yolo claude  # Uses custom flags instead of --dangerously-skip-permissions

# For commands with hyphens, use underscores in env var names
export YOLO_FLAGS_cursor_agent="--custom-force-flag"
yolo cursor-agent  # Uses custom flags instead of --force

# Override for any command
export YOLO_FLAGS_mycommand="--special-mode"
yolo mycommand  # Uses --special-mode instead of --yolo
```

**Note**: Command names with hyphens (like `cursor-agent`) are converted to underscores in environment variable names (e.g., `YOLO_FLAGS_cursor_agent`).

### Dry-Run Mode

Preview what YOLO would execute without actually running the command:

```bash
# See what would be executed
yolo --dry-run claude "implement feature"

# Output:
# Dry-run mode - would execute:
# claude --dangerously-skip-permissions implement feature

# Combine with worktree mode
yolo -w --dry-run claude "big refactor"
```

## Uninstallation

```bash
# Remove the wrapper
rm ~/.local/bin/yolo

# Remove from PATH (edit your shell config manually)
# Remove this line from ~/.bashrc, ~/.zshrc, etc.:
# export PATH="$HOME/.local/bin:$PATH"
```

## Testing

Run the test suite:

```bash
./test.sh
```

Tests cover:
- Command existence
- Help and version flags
- Error handling
- Flag detection for each command
- Worktree creation
- Argument preservation

## Development

### Project Structure

```
ai-aligned-yolo/
├── .github/
│   └── workflows/
│       ├── test.yml          # Test workflow
│       └── shellcheck.yml    # Linting workflow
├── executable_yolo           # Main wrapper script
├── install.sh                # Installation script
├── test.sh                   # Test suite
├── README.md                 # This file
└── LICENSE                   # Apache 2.0 license
```

### Running ShellCheck

```bash
shellcheck executable_yolo install.sh test.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests (`./test.sh`)
5. Run ShellCheck
6. Submit a pull request

## Troubleshooting

### Command not found

If `yolo` is not found after installation:

1. Check PATH:
   ```bash
   echo $PATH | grep ".local/bin"
   ```

2. If not present, add manually:
   ```bash
   # bash/zsh
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc

   # fish
   set -Ux PATH $HOME/.local/bin $PATH
   ```

### Worktree creation fails

Make sure you're in a git repository:
```bash
git status
```

If you get "not in a git repository", initialize one:
```bash
git init
git add .
git commit -m "Initial commit"
```

### Command already has flags

YOLO adds flags to commands. If your command already has conflicting flags, they may clash. In that case, call the command directly without YOLO.

## Related Projects

- [ai-aligned-git](https://github.com/trieloff/ai-aligned-git) - Constrains AI tools to safer git practices
- [ai-aligned-gh](https://github.com/trieloff/ai-aligned-gh) - Ensures proper bot attribution for GitHub operations
- [vibe-coded-badge-action](https://github.com/trieloff/vibe-coded-badge-action) - Badge that visualizes AI contributions in your repo
- [gh-workflow-peek](https://github.com/trieloff/gh-workflow-peek) - Filter and analyze GitHub Actions logs quickly

## License

Apache License 2.0

Copyright 2025 Lars Trieloff

## Credits

Inspired by the need to quickly launch AI coding assistants without remembering arcane flag combinations, and the desire to experiment safely with git worktrees.
