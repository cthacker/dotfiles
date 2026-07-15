# 🚀 Modern Dotfiles

A clean, cross-platform dotfiles setup for macOS and Linux with modern tools.

## ✨ Features

- **Cross-platform**: Works seamlessly on both macOS and Linux
- **Modern tools**: Uses the latest terminal, shell, and editor technologies
- **Easy installation**: Simple setup and uninstallation scripts
- **Modular design**: Pick what you need, ignore what you don't
- **Atom One Dark Theme**: Consistent theme across Neovim, Vim, and Tmux
- **Auto-backup**: Your existing configuration is automatically backed up

## 🛠 What's Included

- **Shell**: Zsh with [Starship](https://starship.rs/) prompt
- **Terminal**: Support for any modern terminal with true color support
- **Text Editors**:
  - Neovim with modern plugins and native LSP for development
  - Full Lua configuration with lazy.nvim for plugin management
  - TreeSitter for improved syntax highlighting
  - NvimTree for fast file navigation
  - Telescope for fuzzy finding
  - LSP configurations for common languages
  - Vim configuration for quick edits
- **Terminal Multiplexers**:
  - Tmux for session management with Atom One Dark theme
  - Herdr on macOS for agent-aware workspaces, tabs, and panes
- **Agent skills**: `bro` rewrites the previous response in plain language
- **Git**: Optimized Git configuration with helpful aliases
- **Modern Utilities**:
  - `bat` - A better `cat` with syntax highlighting
  - `eza` - A modern replacement for `ls`
  - `fzf` - Fuzzy finder for your shell
  - `fzf-tab` - Fuzzy completion for tab (type partial matches and select with fzf)
  - `ripgrep` - Fast code searching

## 🚀 Installation

### Prerequisites

- Git
- Zsh (recommended)
- A Nerd Font (for icons support)

### Quick Install

1. Clone this repository:
   ```bash
   git clone https://github.com/cthacker/dotfiles.git
   cd dotfiles
   ```

2. Run the installation script for your platform:
   ```bash
   # For macOS
   ./install_mac.sh

   # For Linux
   ./install_linux.sh
   ```

3. Install Neovim plugins:
   ```bash
   nvim
   # Lazy.nvim will automatically install plugins when you first open Neovim
   ```

4. Restart your terminal to apply all changes.

### Custom Installation

If you want to install only specific components, you can use the individual scripts in the `scripts` folder.

## 🧹 Uninstallation

If you want to revert to your previous configuration:

```bash
./scripts/uninstall.sh
```

This will restore your backed-up dotfiles from `~/.dotfiles_backup`.

## 📁 Directory Structure

```
dotfiles/
├── config/               # Configuration files for applications
│   ├── nvim/             # Neovim configuration
│   │   ├── init.lua      # Main Neovim entry point
│   │   └── lua/user/     # Modular Lua configurations
│   ├── agents/skills/    # Cross-agent skills (~/.agents/skills)
│   ├── herdr/            # Herdr keybindings and settings
│   └── starship/         # Starship prompt configuration
├── scripts/              # Installation and utility scripts
├── zsh/                  # Zsh-specific files
│   └── zshrc             # Main Zsh configuration
├── vim/                  # Vim configuration and plugins
├── tmux.conf             # Tmux configuration with Atom One theme
├── install_mac.sh        # macOS installation script
├── install_linux.sh      # Linux installation script
└── CLAUDE.md             # Guide and standards for this repo
```

## 🔄 Keeping Updated

To update your dotfiles to the latest version:

```bash
cd ~/dotfiles
git pull
./install_mac.sh   # or install_linux.sh
```

## 🎨 Themes and Customization

The configuration uses Atom One Dark theme across all tools for a consistent experience. To modify the theme:

- **Neovim**: Edit `config/nvim/lua/plugins/onedark.lua`
- **Tmux**: Modify color variables in `tmux.conf`
- **Herdr**: Modify keybindings in `config/herdr/config.toml`
- **Starship**: Change themes with `./scripts/switch_starship_theme.sh`

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.


