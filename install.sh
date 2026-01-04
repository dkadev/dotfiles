#!/bin/bash

# ============================================================================
# Dotfiles Installation Script
# 
# This script installs and configures a complete development environment with:
# - zsh as the default shell
# - Oh My Zsh framework
# - Powerlevel10k theme
# - Various plugins and tools (bat, fzf, eza, etc.)
# - Required fonts and configurations
# ============================================================================

# ============================================================================
# Color Definitions
# ============================================================================
# Terminal color codes for better visual feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Print colored message
# Args:
#   $1: Color variable
#   $2: Message to display
print_colored() {
    echo -e "${1}${2}${RESET}"
}

# Print section header
# Args:
#   $1: Section title
print_header() {
    echo ""
    print_colored "${BLUE}${BOLD}" "============================================================================"
    print_colored "${BLUE}${BOLD}" " $1"
    print_colored "${BLUE}${BOLD}" "============================================================================"
}

# Check if the script is run with --debug flag
if [[ "$1" != "--debug" ]]; then
    set -e
fi

# ============================================================================
# Privilege Escalation
# ============================================================================
# Elevate script to run with sudo if not already
# This ensures the script has the necessary permissions to change the default shell and install packages.
# If the script is not run as root, it will prompt for sudo access.
# If sudo access is not granted, it will exit with an error message.
if [[ $EUID -ne 0 ]]; then
    print_colored "${YELLOW}" "This script must be run as root. Please enter your password to continue."
    sudo -v
fi

# ============================================================================
# Helper Functions
# ============================================================================

# Detect operating system
# Returns: "macos", "debian", or "unknown"
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Install a package based on OS
# Args:
#   $1: Package name for Debian-based systems
#   $2: Package name for macOS (optional, defaults to $1)
# Returns: 0 on success, 1 on failure
install_package() {
    local package=$1
    local macos_package=${2:-$package}  # Use the first package name for macOS if not specified
    
    local os_type=$(detect_os)
    print_colored "${CYAN}" "Installing $package..."
    
    case "$os_type" in
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                print_colored "${RED}" "Homebrew not found. Please install Homebrew first."
                exit 1
            fi
            brew install "$macos_package"
            ;;
        "debian")
            sudo apt-get -qq install -y "$package" >/dev/null 2>&1 || {
                print_colored "${RED}" "Failed to install $package. Please check your package manager."
                return 1
            }
            ;;
        *)
            print_colored "${RED}" "Unsupported OS. Please install $package manually."
            return 1
            ;;
    esac
    
    print_colored "${GREEN}" "✓ $package installed successfully."
}

# ============================================================================
# Main Installation Process
# ============================================================================
print_colored "${MAGENTA}${BOLD}" "🚀 Starting dotfiles installation..."

print_header "ZSH Installation and Configuration"
print_colored "${CYAN}" "Checking for zsh..."
if ! command -v zsh >/dev/null 2>&1; then
    print_colored "${YELLOW}" "zsh not found."
    install_package zsh
else
    print_colored "${GREEN}" "✓ zsh is already installed."
fi

print_colored "${CYAN}" "Verifying zsh installation:"
zsh --version

print_colored "${CYAN}" "Setting zsh as your default shell..."
ZSH_PATH=$(which zsh)
sudo chsh -s "$ZSH_PATH" "$USER"
print_colored "${GREEN}" "✓ Default shell changed to zsh."

print_header "Dependency Installation"
# Check if curl is installed
print_colored "${CYAN}" "Checking for curl..."
if ! command -v curl >/dev/null 2>&1; then
    print_colored "${YELLOW}" "curl not found."
    install_package curl
else
    print_colored "${GREEN}" "✓ curl is already installed."
fi

print_header "Oh My Zsh Installation and Plugins"
print_colored "${CYAN}" "Installing Oh My Zsh..."
export RUNZSH=no  # Don't run zsh after installation
export CHSH=no    # Don't change shell during installation (we already did that)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
print_colored "${GREEN}" "✓ Oh My Zsh installed successfully."

print_colored "${CYAN}" "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" >/dev/null 2>&1
print_colored "${GREEN}" "✓ Powerlevel10k theme installed."

print_colored "${CYAN}" "Installing Oh My Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions > /dev/null 2>&1
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting > /dev/null 2>&1
print_colored "${GREEN}" "✓ Oh My Zsh plugins installed."

print_header "Additional Tools Installation"
# Install bat (improved cat replacement)
install_package bat

# Handle bat symlink only on Debian-based systems
# On Debian, bat is installed as batcat, so we create a symlink for compatibility
if [[ $(detect_os) == "debian" ]]; then
    print_colored "${CYAN}" "Creating symlink for batcat as bat..."
    mkdir -p ~/.local/bin
    ln -sf /usr/bin/batcat ~/.local/bin/bat
    print_colored "${GREEN}" "✓ Symlink created."
fi

# Install fzf (fuzzy finder)
install_package fzf

# Handle fzf preview only on Debian-based systems
if [[ $(detect_os) == "debian" ]]; then
    print_colored "${CYAN}" "Setting up fzf preview script..."
    sudo wget https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/bin/fzf-preview.sh -O /bin/fzf-preview.sh >/dev/null 2>&1 || {
        print_colored "${RED}" "Failed to download fzf preview script. Please check your network connection."
        exit 1
    }
    sudo chmod +x /bin/fzf-preview.sh
    print_colored "${GREEN}" "✓ fzf preview script installed."
fi

# Install eza (modern replacement for ls)
install_package eza

# Install GNU Stow (symlink farm manager for dotfiles)
install_package stow

print_header "Dotfiles Setup with Stow"
rm -rf ~/.zshrc
print_colored "${CYAN}" "Creating symlinks for configuration files..."
stow zsh
stow oh-my-zsh
stow tmux
print_colored "${GREEN}" "✓ Configuration files linked."

print_header "Font Installation"
# Install Hack Nerd Font (patched font with icons)
print_colored "${YELLOW}" "Font installation is optional (e.g., not needed for SSH servers)."
read -p "Do you want to install Hack Nerd Font? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_colored "${CYAN}" "Installing Hack Nerd Font..."
    mkdir -p $HOME/.fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip -O $HOME/.fonts/Hack.zip > /dev/null 2>&1
    unzip -o $HOME/.fonts/Hack.zip -x README.md LICENSE.md -d $HOME/.fonts/ > /dev/null 2>&1
    rm $HOME/.fonts/Hack.zip 2>/dev/null
    print_colored "${GREEN}" "✓ Hack Nerd Font installed."
else
    print_colored "${CYAN}" "Skipping font installation."
fi

# ============================================================================
# Completion Message
# ============================================================================
echo ""
print_colored "${GREEN}${BOLD}" "=============================================="
print_colored "${GREEN}${BOLD}" "✅ Dotfiles installation complete!"
print_colored "${GREEN}${BOLD}" ""
print_colored "${CYAN}${BOLD}" "Next steps:"
print_colored "${CYAN}" "  1. Log out and log back in to start using zsh as your default shell."
print_colored "${CYAN}" "  2. If you use a terminal emulator, set your font to 'Hack Nerd Font' for best appearance."
print_colored "${CYAN}" "  3. Review your ~/.zshrc and customize as needed."
print_colored "${GREEN}${BOLD}" ""
print_colored "${MAGENTA}${BOLD}" "Enjoy your new environment! 🚀"
print_colored "${GREEN}${BOLD}" "=============================================="
