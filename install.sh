#!/bin/bash

# yolo Installer Script
# Installs the yolo wrapper to ~/.local/bin
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
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)
            if [ -f "$HOME/.zshrc" ]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zshrc"
            fi
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

# Function to add directory to PATH in shell config
add_to_path() {
    local dir=$1
    local config_file=$2
    local shell_name
    shell_name=$(detect_shell)
    
    print_color "$YELLOW" "Adding $dir to PATH in $config_file..."
    
    # Create config file if it doesn't exist
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"
    
    # Check if PATH export already exists
    if grep -q "export PATH.*$dir" "$config_file" 2>/dev/null || \
       grep -q "set -gx PATH.*$dir" "$config_file" 2>/dev/null || \
       grep -q "set paths.*$dir" "$config_file" 2>/dev/null; then
        print_color "$GREEN" "✓ $dir already in PATH configuration"
        return 0
    fi
    
    # Add PATH export based on shell
    case "$shell_name" in
        fish)
            echo "set -gx PATH $dir \$PATH" >> "$config_file"
            ;;
        elvish)
            echo "# Added by yolo installer" >> "$config_file"
            echo "set paths = [$dir \$@paths]" >> "$config_file"
            ;;
        *)
            echo "export PATH=\"$dir:\$PATH\"" >> "$config_file"
            ;;
    esac
    
    print_color "$GREEN" "✓ Added $dir to PATH"
}

# Function to prompt user (handles non-interactive mode)
prompt_yes_no() {
    local prompt=$1
    local default=${2:-n}
    
    # In non-interactive mode, use default
    if [ ! -t 0 ]; then
        [ "$default" = "y" ]
        return $?
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to verify git is installed
check_git_installed() {
    print_color "$BLUE" "Checking for git installation..."
    
    if ! command_exists git; then
        print_color "$RED" "✗ Git is not installed"
        print_color "$YELLOW" "Git is recommended for worktree functionality."
        print_color "$YELLOW" "Please install git:"
        case "$(uname -s)" in
            Darwin*)
                print_color "$YELLOW" "  brew install git"
                ;;
            Linux*)
                if command_exists apt-get; then
                    print_color "$YELLOW" "  sudo apt-get install git"
                elif command_exists yum; then
                    print_color "$YELLOW" "  sudo yum install git"
                elif command_exists pacman; then
                    print_color "$YELLOW" "  sudo pacman -S git"
                fi
                ;;
        esac
        return 1
    fi
    
    local git_version
    git_version=$(git --version | awk '{print $3}')
    print_color "$GREEN" "✓ Git version $git_version found"
    return 0
}

# Function to create ~/.local/bin if it doesn't exist
ensure_install_dir() {
    print_color "$BLUE" "Checking installation directory..."
    print_verbose "Installation directory: $INSTALL_DIR"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        print_color "$YELLOW" "Creating $INSTALL_DIR..."
        print_verbose "Directory does not exist, creating it"
        if mkdir -p "$INSTALL_DIR"; then
            print_color "$GREEN" "✓ Created $INSTALL_DIR"
            print_verbose "Directory created successfully"
        else
            print_color "$RED" "✗ Failed to create $INSTALL_DIR"
            print_verbose "Failed to create directory"
            return 1
        fi
    else
        print_color "$GREEN" "✓ $INSTALL_DIR exists"
        print_verbose "Directory already exists"
    fi
    
    # Check if directory is writable
    print_verbose "Checking if directory is writable..."
    if [ ! -w "$INSTALL_DIR" ]; then
        print_color "$RED" "✗ $INSTALL_DIR is not writable"
        print_verbose "Directory permissions: $(ls -ld "$INSTALL_DIR" 2>/dev/null)"
        return 1
    fi
    
    print_color "$GREEN" "✓ $INSTALL_DIR is writable"
    return 0
}

# Function to download file
download_file() {
    local url=$1
    local output=$2
    
    print_verbose "Attempting to download: $url -> $output"
    
    if command_exists curl; then
        print_verbose "Using curl for download"
        if [ "$VERBOSE" = true ]; then
            curl -fL "$url" -o "$output"
        else
            curl -fsSL "$url" -o "$output"
        fi
    elif command_exists wget; then
        print_verbose "Using wget for download"
        if [ "$VERBOSE" = true ]; then
            wget "$url" -O "$output"
        else
            wget -q "$url" -O "$output"
        fi
    else
        print_color "$RED" "✗ Neither curl nor wget found. Please install one of them."
        return 1
    fi
    
    local result=$?
    if [ $result -eq 0 ]; then
        print_verbose "Download successful"
    else
        print_verbose "Download failed with exit code: $result"
    fi
    return $result
}

# Function to install the script
install_script() {
    local dest_path="$INSTALL_DIR/$SCRIPT_NAME"
    local temp_file
    
    print_color "$BLUE" "Installing yolo..."
    
    # Check if yolo already exists
    if [ -f "$dest_path" ] && [ "$UPGRADE" != "true" ]; then
        print_color "$YELLOW" "⚠ yolo already exists at $dest_path"
        if ! prompt_yes_no "Do you want to overwrite it? [y/N] " "n"; then
            print_color "$YELLOW" "Installation cancelled"
            return 1
        fi
    elif [ -f "$dest_path" ] && [ "$UPGRADE" = "true" ]; then
        print_color "$YELLOW" "Upgrading existing yolo at $dest_path"
    fi
    
    # Remove existing file if upgrading
    if [ "$UPGRADE" = "true" ] && [ -f "$dest_path" ]; then
        print_verbose "Removing existing wrapper for upgrade"
        if ! rm -f "$dest_path"; then
            print_color "$RED" "✗ Failed to remove existing wrapper for upgrade"
            return 1
        fi
    fi
    
    # Check if we're running from a local checkout or via curl
    if [ -t 0 ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/$SOURCE_SCRIPT" ]; then
        # Local installation
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local source_path="$script_dir/$SOURCE_SCRIPT"
        print_verbose "Running from local checkout at: $script_dir"
        
        if [ ! -f "$source_path" ]; then
            print_color "$RED" "✗ Source script not found: $source_path"
            return 1
        fi
        
        # Copy the script
        if ! cp "$source_path" "$dest_path"; then
            print_color "$RED" "✗ Failed to copy script to $dest_path"
            return 1
        fi
    else
        # Remote installation via curl | sh
        print_color "$YELLOW" "Downloading executable_yolo from GitHub..."
        temp_file=$(mktemp)
        print_verbose "Created temporary file: $temp_file"
        print_verbose "Downloading from: $RAW_BASE_URL/$SOURCE_SCRIPT"
        
        if ! download_file "$RAW_BASE_URL/$SOURCE_SCRIPT" "$temp_file"; then
            print_color "$RED" "✗ Failed to download executable_yolo"
            rm -f "$temp_file"
            return 1
        fi
        
        # Move to destination
        if ! mv "$temp_file" "$dest_path"; then
            print_color "$RED" "✗ Failed to install script"
            return 1
        fi
    fi
    
    # Make it executable
    if ! chmod +x "$dest_path"; then
        print_color "$RED" "✗ Failed to make script executable"
        return 1
    fi
    
    print_color "$GREEN" "✓ Installed yolo to $dest_path"
    return 0
}

# Function to verify installation
verify_installation() {
    print_color "$BLUE" "Verifying installation..."
    
    local wrapper_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    # Check if wrapper exists and is executable
    if [ ! -x "$wrapper_path" ]; then
        print_color "$RED" "✗ yolo not found or not executable at $wrapper_path"
        return 1
    fi
    
    # Check PATH
    if ! is_in_path "$INSTALL_DIR"; then
        print_color "$YELLOW" "⚠ $INSTALL_DIR is not in current PATH"
        print_color "$YELLOW" "  You need to restart your shell or run:"
        local shell_config
        shell_config=$(get_shell_config)
        print_color "$YELLOW" "  source $shell_config"
        return 0
    fi
    
    # Try to execute yolo --version
    if "$wrapper_path" --version >/dev/null 2>&1; then
        print_color "$GREEN" "✓ yolo is working correctly"
    else
        print_color "$YELLOW" "⚠ yolo installed but may not be working correctly"
    fi
    
    print_color "$GREEN" "✓ Installation verified"
    return 0
}

# Main installation function
main() {
    if [ "$UPGRADE" = "true" ]; then
        print_color "$BLUE" "=== yolo Upgrade ==="
    else
        print_color "$BLUE" "=== yolo Installer ==="
    fi
    echo
    print_color "$YELLOW" "This installer will:"
    if [ "$UPGRADE" = "true" ]; then
        print_color "$YELLOW" "  • Upgrade yolo at ~/.local/bin/yolo"
    else
        print_color "$YELLOW" "  • Install yolo to ~/.local/bin/yolo"
        print_color "$YELLOW" "  • Ensure ~/.local/bin is in your PATH"
        print_color "$YELLOW" "  • Verify the installation"
    fi
    echo
    
    if [ "$UPGRADE" != "true" ] && ! prompt_yes_no "Do you want to continue? [Y/n] " "y"; then
        print_color "$YELLOW" "Installation cancelled."
        exit 0
    fi
    echo
    
    # Check prerequisites (optional - git is recommended but not required)
    check_git_installed || print_color "$YELLOW" "⚠ Continuing without git (worktree feature will not work)"
    echo
    
    # Ensure installation directory exists
    if ! ensure_install_dir; then
        exit 1
    fi
    
    # Check PATH
    if ! is_in_path "$INSTALL_DIR"; then
        print_color "$YELLOW" "⚠ $INSTALL_DIR is not in PATH"
        echo
        local shell_config
        shell_config=$(get_shell_config)
        
        if prompt_yes_no "Do you want to add it to $shell_config? [Y/n] " "y"; then
            add_to_path "$INSTALL_DIR" "$shell_config"
        else
            echo
            print_color "$YELLOW" "To add it manually, run:"
            local shell_name
            shell_name=$(detect_shell)
            case "$shell_name" in
                fish)
                    print_color "$WHITE" "  echo 'set -gx PATH $INSTALL_DIR \$PATH' >> $shell_config"
                    ;;
                elvish)
                    print_color "$WHITE" "  echo 'set paths = [$INSTALL_DIR \$@paths]' >> $shell_config"
                    ;;
                *)
                    print_color "$WHITE" "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> $shell_config"
                    ;;
            esac
        fi
    else
        print_color "$GREEN" "✓ $INSTALL_DIR is already in PATH"
    fi
    
    echo
    # Install the script
    if ! install_script; then
        exit 1
    fi
    
    # Verify installation
    verify_installation
    
    echo
    print_color "$GREEN" "=== Installation Complete ==="
    print_color "$BLUE" "yolo has been installed successfully!"
    echo
    print_color "$YELLOW" "Next steps:"
    if ! is_in_path "$INSTALL_DIR"; then
        print_color "$YELLOW" "1. Reload your shell configuration:"
        print_color "$YELLOW" "   source $(get_shell_config)"
        print_color "$YELLOW" "   Or start a new terminal session"
        echo
    fi
    print_color "$YELLOW" "2. Try it out:"
    print_color "$YELLOW" "   yolo --help"
    print_color "$YELLOW" "   yolo claude echo 'Hello from Claude!'"
    print_color "$YELLOW" "   yolo -w amp your-command"
    echo
    print_color "$BLUE" "To uninstall, run:"
    print_color "$BLUE" "  rm ~/.local/bin/yolo"
}

# Uninstall function
uninstall() {
    print_color "$BLUE" "=== yolo Uninstaller ==="
    echo
    
    local wrapper_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    if [ -f "$wrapper_path" ]; then
        print_color "$YELLOW" "Removing yolo..."
        if rm -f "$wrapper_path"; then
            print_color "$GREEN" "✓ Removed $wrapper_path"
        else
            print_color "$RED" "✗ Failed to remove $wrapper_path"
            exit 1
        fi
    else
        print_color "$YELLOW" "yolo not found at $wrapper_path"
    fi
    
    echo
    print_color "$GREEN" "=== Uninstall Complete ==="
    print_color "$YELLOW" "Note: PATH modifications in your shell config were not removed"
    local shell_config
    shell_config=$(get_shell_config)
    print_color "$YELLOW" "You may want to manually remove the PATH export from $shell_config"
}

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        --verbose|-v)
            VERBOSE=true
            print_verbose "Verbose mode enabled"
            ;;
        --upgrade|-U)
            UPGRADE=true
            ;;
    esac
done

case "${1:-}" in
    --uninstall|-u)
        uninstall
        ;;
    --verbose|-v)
        # If only --verbose is passed, run main
        if [ $# -eq 1 ]; then
            main
        fi
        ;;
    --upgrade|-U)
        # Run main in upgrade mode
        main
        ;;
    --help|-h)
        echo "yolo Installer"
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --verbose, -v   Enable verbose output"
        echo "  --upgrade, -U   Upgrade existing installation"
        echo "  --uninstall, -u Uninstall yolo"
        echo "  (no options)    Install yolo"
        echo ""
        echo "Examples:"
        echo "  $0              # Install normally"
        echo "  $0 --verbose    # Install with detailed output"
        echo "  $0 -v           # Same as --verbose"
        echo "  $0 --upgrade    # Upgrade existing installation"
        echo "  $0 --uninstall  # Remove yolo"
        ;;
    *)
        main
        ;;
esac
