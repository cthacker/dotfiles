# 🚀 Modern Dotfiles

A clean, cross-platform dotfiles setup for macOS and Linux with modern tools.

![Terminal Preview](https://user-images.githubusercontent.com/YOUR_GITHUB_ID/YOUR_REPO_NAME/main/screenshots/terminal.png)

## ✨ Features

- **Cross-platform**: Works seamlessly on both macOS and Linux
- **Modern tools**: Uses the latest terminal, shell, and editor technologies
- **Easy installation**: Simple setup and uninstallation scripts
- **Modular design**: Pick what you need, ignore what you don't
- **Auto-backup**: Your existing configuration is automatically backed up

## 🛠 What's Included

- **Shell**: Zsh with [Starship](https://starship.rs/) prompt
- **Terminal**: [Ghostty](https://ghostty.dev/) - Modern, GPU-accelerated terminal emulator
- **Text Editors**:
  - Neovim with modern plugins and native LSP for development
  - Vim configuration for quick edits
- **Terminal Multiplexer**: Tmux for session management
- **Git**: Optimized Git configuration
- **Utilities**:
  - `bat` - A better `cat` with syntax highlighting
  - `eza` - A modern replacement for `ls`
  - `fd` - A faster alternative to `find`
  - `fzf` - Fuzzy finder for your shell
  - `ripgrep` - Fast code searching

## 🚀 Installation

### Prerequisites

- Git
- Zsh (recommended)

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

3. Install Starship prompt:
   ```bash
   ./scripts/install_starship.sh
   ```

4. Start Neovim and install plugins:
   ```bash
   nvim
   # Inside Neovim, run:
   :PlugInstall
   ```

5. Restart your terminal to apply all changes.

### Custom Installation

If you want to install only specific components, you can use the individual scripts in the `scripts` folder.

## 🧹 Uninstallation

If you want to revert to your previous configuration:

```bash
./uninstall.sh
```

This will restore your backed-up dotfiles from `~/.dotfiles_backup`.

## 📁 Directory Structure

```
dotfiles/
├── config/               # Configuration files for various applications
│   ├── nvim/             # Neovim configuration
│   ├── starship/         # Starship prompt configuration
│   └── ...               # Other config folders
├── scripts/              # Installation and utility scripts
│   ├── install_starship.sh # Starship installation script
│   ├── cleanup_prezto.sh # Script to remove Prezto
│   └── ...               # Other utility scripts
├── zsh/                  # Zsh-specific files
│   └── zshrc             # Main Zsh configuration
├── vim/                  # Vim configuration and plugins
├── tmux.conf             # Tmux configuration
├── gitconfig             # Git configuration
├── install_mac.sh        # macOS installation script
├── install_linux.sh      # Linux installation script
└── uninstall.sh          # Uninstallation script
```

## 🔄 Keeping Updated

To update your dotfiles to the latest version:

```bash
cd ~/dotfiles
git pull
./install_mac.sh   # or install_linux.sh
```

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Starship](https://starship.rs/) for the cross-shell prompt
- [Ghostty](https://ghostty.dev/) for the terminal emulator
- Various plugin authors for Neovim, Vim, and Tmux extensions




