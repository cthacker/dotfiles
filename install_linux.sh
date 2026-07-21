#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
echo "🚀 Installing dotfiles for Linux from $DOTFILES_DIR..."

install_latest_neovim() {
    local nvim_arch
    local nvim_temp_dir
    local nvim_archive

    case "$(uname -m)" in
        x86_64) nvim_arch="x86_64" ;;
        aarch64|arm64) nvim_arch="arm64" ;;
        *)
            echo "Unsupported architecture for the official Neovim build: $(uname -m)"
            exit 1
            ;;
    esac

    echo "📦 Installing the latest Neovim release (0.12+ required)..."
    nvim_temp_dir="$(mktemp -d)"
    nvim_archive="$nvim_temp_dir/nvim.tar.gz"
    curl -fL \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${nvim_arch}.tar.gz" \
        -o "$nvim_archive"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    tar -xzf "$nvim_archive" -C "$HOME/.local/opt"
    ln -snf \
        "$HOME/.local/opt/nvim-linux-${nvim_arch}/bin/nvim" \
        "$HOME/.local/bin/nvim"
    rm -rf "$nvim_temp_dir"
    hash -r
}

ensure_neovim_012() {
    if command -v nvim &> /dev/null \
        && nvim --headless --clean '+if !has("nvim-0.12") | cquit | endif' +qa; then
        return
    fi

    install_latest_neovim
    if ! nvim --headless --clean '+if !has("nvim-0.12") | cquit | endif' +qa; then
        echo "Neovim 0.12 or newer is required by this configuration."
        exit 1
    fi
}

ensure_tree_sitter_cli() {
    local minimum_version="0.26.1"
    local installed_version=""

    if command -v tree-sitter &> /dev/null; then
        installed_version="$(tree-sitter --version | awk '{ print $2 }')"
        if [ "$(printf '%s\n' "$minimum_version" "$installed_version" | sort -V | head -n 1)" = "$minimum_version" ]; then
            return
        fi
    fi

    echo "📦 Installing tree-sitter-cli ${minimum_version}+..."
    if ! command -v cargo &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    cargo install tree-sitter-cli --locked
    hash -r

    installed_version="$(tree-sitter --version | awk '{ print $2 }')"
    if [ "$(printf '%s\n' "$minimum_version" "$installed_version" | sort -V | head -n 1)" != "$minimum_version" ]; then
        echo "tree-sitter-cli ${minimum_version} or newer is required."
        exit 1
    fi
}

# Check distribution
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu based
    echo "📦 Detected Debian/Ubuntu based distribution"

    # Update package lists
    echo "📦 Updating package lists..."
    sudo apt update

    # Install dependencies
    echo "📦 Installing essential packages..."
    sudo apt install -y neovim ripgrep tmux nodejs npm python3-pip curl wget git zsh unzip zsh-history-substring-search build-essential

    # Install additional packages
    sudo apt install -y bat fzf

    # On Debian/Ubuntu, bat is installed as batcat - create symlink
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
        echo "Created bat symlink for batcat"
    fi

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
    # dnf uses status 100 to mean updates are available; that is not an error.
    sudo dnf check-update || [ "$?" -eq 100 ]

    # Install dependencies
    echo "📦 Installing essential packages..."
    sudo dnf install -y neovim ripgrep tmux nodejs npm python3-pip curl wget git zsh bat fzf unzip gcc gcc-c++ make

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
    sudo pacman -S --noconfirm neovim ripgrep tmux nodejs npm python-pip curl wget git zsh bat fzf unzip base-devel

    # Try to install eza
    if ! sudo pacman -S --noconfirm eza 2>/dev/null; then
        echo "📦 Installing Eza via cargo..."
        if ! command -v cargo &> /dev/null; then
            sudo pacman -S --noconfirm rust
        fi
        cargo install eza
    fi
else
    echo "Unsupported Linux distribution. Supported families: Debian/Ubuntu, Fedora, and Arch."
    exit 1
fi

ensure_neovim_012
ensure_tree_sitter_cli

# Install fzf-tab (not available in package managers, clone from git)
echo "📦 Installing fzf-tab..."
FZF_TAB_DIR="$HOME/.local/share/fzf-tab"
if [ ! -d "$FZF_TAB_DIR" ]; then
  git clone https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR"
else
  echo "fzf-tab already installed, updating..."
  git -C "$FZF_TAB_DIR" pull
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
echo "Neovim plugins will be automatically installed by lazy.nvim on first launch"
echo "Restart your terminal to apply all changes"
