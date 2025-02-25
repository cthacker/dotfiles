#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Installing dotfiles for macOS from $DOTFILES_DIR..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "🍺 Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for the current session
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "🍺 Homebrew already installed. Updating..."
    brew update
fi

# Install essential tools
echo "📦 Installing essential packages..."
brew install neovim
brew install ripgrep
brew install tmux
brew install node
brew install fzf
brew install bat
brew install eza
brew install jq
brew install starship
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting

# Install fonts - direct download method
echo "🔤 Installing fonts with ligature support..."
FONT_DIR="$HOME/Library/Fonts"
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

# Install Python packages
echo "🐍 Installing Python packages..."
pip3 install --user pynvim

# Install Node packages
echo "📦 Installing Node packages..."
npm install -g neovim

# Backup and link dotfiles
echo "🔄 Backing up and linking dotfiles..."
source "$DOTFILES_DIR/scripts/backup_link.sh"

echo "✅ Installation complete!"
echo "Run 'nvim' and execute ':PlugInstall' to install Neovim plugins"
echo "Restart your terminal to apply all changes"
