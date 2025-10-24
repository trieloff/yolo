#!/bin/bash

# YOLO Installer Script
# Installs the yolo command to ~/.local/bin
# Supports both local installation and curl | sh
#
# Usage with curl:
#   curl -fsSL https://raw.githubusercontent.com/trieloff/yolo/main/install.sh | sh
#   UPGRADE=true curl -fsSL https://raw.githubusercontent.com/trieloff/yolo/main/install.sh | sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="yolo"
SOURCE_SCRIPT="executable_yolo"
RAW_BASE_URL="https://raw.githubusercontent.com/trieloff/yolo/main"

# Verbose mode flag
VERBOSE=${VERBOSE:-false}
# Upgrade mode flag
UPGRADE=${UPGRADE:-false}

# Function to print colored output
print_color() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

# Function to print verbose output
print_verbose() {
    if [ "$VERBOSE" = true ]; then
        print_color "$BLUE" "[VERBOSE] $*"
    fi
}

# Function to check if a command exists
command_exists() {
    local cmd="$1"
    print_verbose "Checking if command '$cmd' exists..."
    if command -v "$cmd" >/dev/null 2>&1; then
        print_verbose "Command '$cmd' found at: $(command -v "$cmd")"
        return 0
    else
        print_verbose "Command '$cmd' not found"
        return 1
    fi
}

# Function to check if directory is in PATH
is_in_path() {
    local dir=$1
    print_verbose "Checking if '$dir' is in PATH..."
    print_verbose "Current PATH: $PATH"
    if [[ ":$PATH:" == *":$dir:"* ]]; then
        print_verbose "Directory '$dir' is in PATH"
        return 0
    else
        print_verbose "Directory '$dir' is NOT in PATH"
        return 1
    fi
}

# Function to detect the user's shell
detect_shell() {
    print_verbose "Detecting shell..."
    if [ -n "$SHELL" ]; then
        local shell_name
        shell_name=$(basename "$SHELL")
        print_verbose "Detected shell: $shell_name (from SHELL=$SHELL)"
        echo "$shell_name"
    else
        print_verbose "SHELL variable not set, defaulting to bash"
        echo "bash"
    fi
}

# Function to get shell config file
get_shell_config() {
    local shell_name
    shell_name=$(detect_shell)
    case "$shell_name" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        elvish)
            echo "$HOME/.config/elvish/rc.elv"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_color "$BLUE" "Checking prerequisites..."
    
    # Check if git is installed (needed for worktree support)
    if ! command_exists git; then
        print_color "$YELLOW" "Warning: git is not installed"
        print_color "$YELLOW" "Worktree functionality will not be available"
    else
        print_color "$GREEN" "✓ git is installed"
    fi
    
    print_color "$GREEN" "✓ Prerequisites check complete"
}

# Main installation
print_color "$BLUE" "=== YOLO Installer ==="
echo

# Check prerequisites
check_prerequisites
echo

# Create installation directory
print_color "$BLUE" "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
print_color "$GREEN" "✓ Directory created: $INSTALL_DIR"
echo

# Check if yolo already exists
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ] && [ "$UPGRADE" != "true" ]; then
    # Check if it's our version
    if grep -q "YOLO - Run AI coding agents" "$INSTALL_DIR/$SCRIPT_NAME" 2>/dev/null; then
        print_color "$YELLOW" "YOLO is already installed at $INSTALL_DIR/$SCRIPT_NAME"
        print_color "$YELLOW" "To upgrade, run with UPGRADE=true:"
        print_color "$WHITE" "  UPGRADE=true $0"
        exit 0
    else
        print_color "$RED" "Warning: $INSTALL_DIR/$SCRIPT_NAME exists but doesn't appear to be YOLO"
        print_color "$YELLOW" "Please backup or remove it before installing"
        exit 1
    fi
fi

# Download or copy the script
print_color "$BLUE" "Installing yolo script..."
if [ -f "$SOURCE_SCRIPT" ]; then
    # Local installation
    print_verbose "Copying from local file: $SOURCE_SCRIPT"
    cp "$SOURCE_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    print_color "$GREEN" "✓ Script installed from local file"
else
    # Remote installation
    print_verbose "Downloading from: $RAW_BASE_URL/$SOURCE_SCRIPT"
    if command_exists curl; then
        curl -fsSL "$RAW_BASE_URL/$SOURCE_SCRIPT" -o "$INSTALL_DIR/$SCRIPT_NAME"
    elif command_exists wget; then
        wget -q "$RAW_BASE_URL/$SOURCE_SCRIPT" -O "$INSTALL_DIR/$SCRIPT_NAME"
    else
        print_color "$RED" "Error: Neither curl nor wget is available"
        exit 1
    fi
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    print_color "$GREEN" "✓ Script downloaded and installed"
fi
echo

# Check if directory is in PATH
if is_in_path "$INSTALL_DIR"; then
    print_color "$GREEN" "✓ $INSTALL_DIR is already in your PATH"
else
    print_color "$YELLOW" "⚠ $INSTALL_DIR is not in your PATH"
    echo
    print_color "$YELLOW" "To add it to your PATH, run:"
    
    config_file=$(get_shell_config)
    shell_name=$(detect_shell)
    
    case "$shell_name" in
        fish)
            print_color "$WHITE" "  echo 'set -gx PATH $INSTALL_DIR \$PATH' >> $config_file"
            print_color "$WHITE" "  source $config_file"
            ;;
        elvish)
            print_color "$WHITE" "  echo 'set paths = [$INSTALL_DIR \$@paths]' >> $config_file"
            print_color "$WHITE" "  # Then restart your shell or source the file"
            ;;
        *)
            print_color "$WHITE" "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> $config_file"
            print_color "$WHITE" "  source $config_file"
            ;;
    esac
fi

echo
print_color "$GREEN" "=== Installation Complete! ==="
echo
print_color "$BLUE" "The YOLO command has been installed."
echo
print_color "$YELLOW" "What it does:"
print_color "$WHITE" "  • Runs AI coding agents with appropriate bypass flags"
print_color "$WHITE" "  • Supports worktree creation for isolated work (-w flag)"
print_color "$WHITE" "  • Maps agent commands to their specific flags automatically"
echo
print_color "$YELLOW" "Supported agents:"
print_color "$WHITE" "  • codex    - Anthropic Code"
print_color "$WHITE" "  • claude   - Claude Code"
print_color "$WHITE" "  • copilot  - GitHub Copilot"
print_color "$WHITE" "  • droid    - Factory AI Droid"
print_color "$WHITE" "  • amp      - Sourcegraph Amp"
print_color "$WHITE" "  • cursor-agent - Cursor Agent"
print_color "$WHITE" "  • opencode - OpenCode AI"
print_color "$WHITE" "  • <other>  - Any other command (adds --yolo)"
echo
print_color "$YELLOW" "Usage examples:"
print_color "$WHITE" "  yolo claude 'Fix the bug in src/main.js'"
print_color "$WHITE" "  yolo -w droid 'Refactor authentication'"
print_color "$WHITE" "  yolo --help"
echo
print_color "$GREEN" "Enjoy faster AI-assisted development!"
