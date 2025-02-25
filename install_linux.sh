#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Installing dotfiles for Linux from $DOTFILES_DIR..."

# Check distribution
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu based
    echo "📦 Detected Debian/Ubuntu based distribution"
    
    # Update package lists
    echo "📦 Updating package lists..."
    sudo apt update
    
    # Install dependencies
    echo "📦 Installing essential packages..."
    sudo apt install -y neovim ripgrep tmux nodejs npm python3-pip curl wget git zsh unzip
    
    # Install additional packages
    sudo apt install -y bat fzf
    
    # Install Eza (modern replacement for ls)
    if ! command -v eza &> /dev/null; then
        if [ -f /etc/debian_version ]; then
            echo "📦 Installing Eza..."
            # Method 1: Using Cargo if available
            if command -v cargo &> /dev/null; then
                cargo install eza
            else
                # Method 2: Install Rust and Cargo, then install eza
                echo "📦 Installing Rust to build eza..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
                cargo install eza
            fi
        fi
    fi
    
elif [ -f /etc/fedora-release ]; then
    # Fedora based
    echo "📦 Detected Fedora based distribution"
    
    # Update package lists
    echo "📦 Updating package lists..."
    sudo dnf check-update
    
    # Install dependencies
    echo "📦 Installing essential packages..."
    sudo dnf install -y neovim ripgrep tmux nodejs npm python3-pip curl wget git zsh bat fzf unzip
    
    # Install Eza
    if ! command -v eza &> /dev/null; then
        echo "📦 Installing Eza..."
        # Try to install via dnf first (if available)
        if ! sudo dnf install -y eza 2>/dev/null; then
            # Otherwise install via cargo
            if ! command -v cargo &> /dev/null; then
                echo "📦 Installing Rust to build eza..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env"
            fi
            cargo install eza
        fi
    fi
    
elif [ -f /etc/arch-release ]; then
    # Arch based
    echo "📦 Detected Arch based distribution"
    
    # Update package lists
    echo "📦 Updating package lists..."
    sudo pacman -Syu
    
    # Install dependencies
    echo "📦 Installing essential packages..."
    sudo pacman -S --noconfirm neovim ripgrep tmux nodejs npm python-pip curl wget git zsh bat fzf unzip
    
    # Try to install eza
    if ! sudo pacman -S --noconfirm eza 2>/dev/null; then
        echo "📦 Installing Eza via cargo..."
        if ! command -v cargo &> /dev/null; then
            sudo pacman -S --noconfirm rust
        fi
        cargo install eza
    fi
fi

# Install Python packages
echo "🐍 Installing Python packages..."
pip3 install --user pynvim

# Install Node packages
echo "📦 Installing Node packages..."
sudo npm install -g neovim

# Install fonts - direct download method
echo "🔤 Installing fonts with ligature support..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Function to download and install a Nerd Font
install_nerd_font() {
  local font_name=$1
  local temp_zip=$(mktemp).zip
  echo "Downloading $font_name Nerd Font..."
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.zip" -o "$temp_zip"
  echo "Installing $font_name Nerd Font..."
  unzip -qo "$temp_zip" -d "$FONT_DIR" -x "*Windows*" "*.md" "LICENSE" "*.txt" "*.rst"
  rm "$temp_zip"
}

# Install popular programming fonts with ligatures
install_nerd_font "FiraCode"
install_nerd_font "JetBrainsMono"
install_nerd_font "Hack"

# Update font cache
if command -v fc-cache &> /dev/null; then
  echo "Updating font cache..."
  fc-cache -f
fi

# Install starship prompt
curl -sS https://starship.rs/install.sh | sh

# Backup and link dotfiles
echo "🔄 Backing up and linking dotfiles..."
source "$DOTFILES_DIR/scripts/backup_link.sh"

echo "✅ Installation complete!"
echo "Run 'nvim' and execute ':PlugInstall' to install Neovim plugins"
echo "Restart your terminal to apply all changes"
