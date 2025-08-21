#!/bin/bash

# Check if the script is run with --debug flag
if [[ "$1" != "--debug" ]]; then
    set -e
fi

# Elevate script to run with sudo if not already
# This ensures the script has the necessary permissions to change the default shell and install packages.
# If the script is not run as root, it will prompt for sudo access.
# If sudo access is not granted, it will exit with an error message.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please enter your password to continue."
    sudo -v
fi

# Detect operating system
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
install_package() {
    local package=$1
    local macos_package=${2:-$package}  # Use the first package name for macOS if not specified
    
    local os_type=$(detect_os)
    echo "Installing $package..."
    
    case "$os_type" in
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                echo "Homebrew not found. Please install Homebrew first."
                exit 1
            fi
            brew install "$macos_package"
            ;;
        "debian")
            sudo apt-get -qq install -y "$package" >/dev/null 2>&1 || {
                echo "Failed to install $package. Please check your package manager."
                return 1
            }
            ;;
        *)
            echo "Unsupported OS. Please install $package manually."
            return 1
            ;;
    esac
    
    echo "$package installed successfully."
}

echo "Checking for zsh..."
if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh not found."
    install_package zsh
else
    echo "zsh is already installed."
fi

echo "Verifying zsh installation:"
zsh --version

echo "Setting zsh as your default shell..."
ZSH_PATH=$(which zsh)
sudo chsh -s "$ZSH_PATH" "$USER"

# Check if curl is installed
echo "Checking for curl..."
if ! command -v curl >/dev/null 2>&1; then
    echo "curl not found."
    install_package curl
else
    echo "curl is already installed."
fi

echo "Installing Oh My Zsh..."
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1

echo "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" >/dev/null 2>&1

echo "Installing Oh My Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions > /dev/null 2>&1
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting > /dev/null 2>&1

install_package bat

# Handle bat symlink only on Debian-based systems
if [[ $(detect_os) == "debian" ]]; then
    echo "Creating symlink for batcat as bat..."
    mkdir -p ~/.local/bin
    ln -sf /usr/bin/batcat ~/.local/bin/bat
fi

install_package fzf

# Handle fzf preview only on Debian-based systems
if [[ $(detect_os) == "debian" ]]; then
    sudo wget https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/bin/fzf-preview.sh -O /bin/fzf-preview.sh >/dev/null 2>&1 || {
        echo "Failed to download fzf preview script. Please check your network connection."
        exit 1
    }
    sudo chmod +x /bin/fzf-preview.sh
fi

install_package eza
install_package stow

rm -rf ~/.zshrc
echo "Creating symlink for .zshrc..."
stow zsh
stow oh-my-zsh
stow tmux

# Ask the user if they want to install additional Nerd Font
echo "Installing Hack Nerd Font..."
mkdir -p $HOME/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip -O $HOME/.fonts/Hack.zip > /dev/null 2>&1
unzip -o $HOME/.fonts/Hack.zip -x README.md LICENSE.md -d $HOME/.fonts/ > /dev/null 2>&1
rm $HOME/.fonts/Hack.zip 2>/dev/null

# Final message
echo ""
echo "=============================================="
echo "All done!"
echo "To start using zsh as your default shell, please log out and log back in."
echo "=============================================="