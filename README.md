# 🚀 YOLO: CODE FIRST, ASK QUESTIONS LATER 🚀

![a_hollywood_movie_poster](https://github.com/user-attachments/assets/e3d0e1e8-0b9a-4f7e-9b6a-6e4e8e1e8e1e)

## THE PROBLEM: AI THAT PLAYS IT TOO SAFE

AI coding assistants are great, but they're cowards. They ask for permission. They worry about "safety" and "best practices." They are holding you back.

## THE SOLUTION: YOLO

YOLO is a wrapper for your favorite AI coding tools that adds the flags you need to get things done. No more hand-holding. No more nagging. Just pure, unadulterated, high-velocity coding.

### 🔥 What YOLO Does

- **Bypasses Safety Approvals:** Who has time for approvals when you're in the zone?
- **Skips Permissions:** Permissions are for people who don't know what they're doing. You do.
- **Forces Actions:** When you say jump, your AI should say "how high?", not "are you sure?"
- **Creates Git Worktrees:** Keep your main branch clean while you experiment with wild, untested ideas.

## 🏃‍♂️ INSTALL NOW AND UNLEASH YOUR AI'S TRUE POTENTIAL

```bash
curl -fsSL https://raw.githubusercontent.com/trieloff/yolo/main/install.sh | sh
```

## 📖 USAGE

Just add `yolo` before your usual AI command:

```bash
# Run claude with reckless abandon
yolo claude "Fix all the bugs in the entire codebase"

# Create a worktree and let droid refactor everything
yolo -w droid "Rewrite the frontend in a more obscure framework"

# See what other tools you can supercharge
yolo --help
```

### Environment Variables

- `YOLO_DEBUG=true`: Print the final command before executing it.
- `YOLO_FLAGS_<agent>`: Override the default flags for a specific agent. For example, `YOLO_FLAGS_claude="--custom-flag"`.

### Worktree Cleanup

When you are done with a worktree, you can clean it up with the following commands:

```bash
# Remove the worktree directory
git worktree remove .conductor/<agent>-<timestamp>

# Prune the worktree
git worktree prune

# Delete the branch
git branch -d yolo/<agent>/<timestamp>
```

## 🌍 SUPPORTED AI TOOLS

- `codex`
- `claude`
- `copilot`
- `droid`
- `amp`
- `cursor-agent`
- `opencode`
- ...and any other tool that needs a little encouragement to break the rules.

## 🔗 The Vibe Coding Ecosystem

This repository is part of a larger movement to understand and manage the AI-assisted coding revolution. Check out these related projects:

- **[AI-Aligned-Git](https://github.com/trieloff/ai-aligned-git)** - The satirical git wrapper that "protects" your repository from reckless AI commits
- **[AI-Aligned-GH](https://github.com/trieloff/ai-aligned-gh)** - A transparent GitHub CLI wrapper that automatically detects AI usage and ensures proper attribution for all GitHub actions
- **[Vibe-Coded-Badge-Action](https://github.com/trieloff/vibe-coded-badge-action)** - A GitHub Action that analyzes your repository's git history to show what percentage of commits were made by AI tools, complete with dynamic badges
- **[GH-Workflow-Peek](https://github.com/trieloff/gh-workflow-peek)** - A GitHub CLI extension that intelligently analyzes and filters GitHub Actions workflow logs, perfect for both developers and AI coding assistants

## License

Apache-2.0. Go nuts.
