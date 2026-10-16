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
│   ├── agents/skills/    # Cross-agent skills
│   │   └── experimental/ # Skills still being trialled
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

### Updating AI tooling

`update-ai` updates every AI/agent CLI on the machine in one pass. It is
symlinked to `~/.local/bin/update-ai` by the installer, so it is available from
any shell.

```bash
update-ai                 # update everything that is installed
update-ai claude codex     # update only the named tools
update-ai --list           # show known tools and whether each is installed
update-ai --help
```

Tools that are not installed are skipped, and one tool failing does not stop the
others — the run ends with a summary and a non-zero exit if anything failed.

| Tool | Install method | Update performed |
| --- | --- | --- |
| `herdr` | official installer → `~/.local/bin` | `herdr update` |
| `pi` | npm global (nvm node) | `pi update --all` (pi + extensions) |
| `omp` | standalone binary → `~/.local/bin` | `omp update`, `omp update --plugins` |
| `claude` | native installer → `~/.local/bin` | `claude update`, `claude plugin marketplace update` |
| `codex` | Homebrew cask | `brew upgrade --cask codex` |
| `grok` | binary in `~/.grok/bin` | `grok update` |
| `gemini` | npm global (Homebrew node) | `npm install -g @google/gemini-cli@latest` |

Gemini CLI has no self-update subcommand, and Node CLIs may live under either
Homebrew's node or an nvm-managed node — each with its own global prefix. The
script detects which `npm` actually owns the package before reinstalling, so it
never installs a stray second copy under the wrong prefix.

## 🧠 Agent Skills

Skills live in `config/agents/skills/`. Anything settled sits at the top level;
anything still being trialled goes in `config/agents/skills/experimental/`.

The installer links every skill into **both** skill roots, since different tools
read different ones:

- `~/.agents/skills/<name>` — Codex and pi
- `~/.claude/skills/<name>` — Claude Code

Links are always **flat**, one directory per skill, even for skills under
`experimental/`. Discovery is not consistent across tools — some recurse into
subdirectories of a skill root and some do not — so a nested layout would load
unevenly. `experimental/` is a repo-side convention
only; what lands in the skill roots is identical either way.

To add a skill, create `config/agents/skills/experimental/<name>/SKILL.md` and
re-run the installer (or `./scripts/backup_link.sh`). To retire one, delete the
directory and re-run `./scripts/uninstall.sh`, which removes both links. Promote
a skill by moving it out of `experimental/` to the top level and re-running the
installer.

New skills should set `disable-model-invocation: true` in their frontmatter so
they only fire when invoked explicitly as `/<name>`.

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


