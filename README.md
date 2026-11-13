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
- **Terminal**: [Ghostty](https://ghostty.org/) config (any true-color terminal works)
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
- **Modern Utilities**:
  - `bat` - A better `cat` with syntax highlighting
  - `eza` - A modern replacement for `ls`
  - `fzf` - Fuzzy finder for your shell
  - `zoxide` - A smarter `cd` that learns your most-used directories
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
│   ├── ghostty/          # Ghostty terminal settings
│   ├── herdr/            # Herdr keybindings and settings
│   ├── rex/              # Rex keybindings (init.lua) and click-to-open panes (opener/)
│   └── starship/         # Starship prompt configuration
├── scripts/              # Installation and utility scripts
├── zsh/                  # Zsh-specific files
│   └── zshrc             # Main Zsh configuration
├── vimrc                 # Vim config, also sourced by Neovim for shared settings
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

## 🦖 Rex

[Rex](https://www.superlogical.com/rex) is the terminal I use for agents. Three pieces make it
work the way I want; the normal install links the first and does not set up the other two.

- **Keybindings** in `config/rex/init.lua`, linked to `~/.config/rex/init.lua`.
- **Rex Opener** (`config/rex/opener/`): Cmd-click a file in a pane to open it in a pane
  beside it, Markdown in Glow and code in nvim, and **Ctrl-Cmd-O** (Caps Lock-Cmd-O) to pick
  any file named on the screen. It installs a small macOS app as the default opener for
  those file types. See [its README](config/rex/opener/README.md).
- **rex-restore**, my own separate, private repository: after Rex restarts, each pane
  reopens the Claude Code, Codex or Pi conversation it had, idle, with approvals handled
  automatically. `zsh/zshrc` loads it from `~/checkouts/rex-restore` when it is there.

The paths are fixed: this repository must be at `~/checkouts/dotfiles` (the picker key in
`init.lua` points there) and rex-restore at `~/checkouts/rex-restore`. On a new Mac, after
the normal install, with Glow, nvim, fzf, Node 22.18+ and the Xcode command-line tools:

```bash
node ~/checkouts/dotfiles/config/rex/opener/install.mjs      # answer macOS's prompts
git clone git@github.com:cthacker/rex-restore.git ~/checkouts/rex-restore
~/checkouts/rex-restore/install.sh
```

rex-restore's installer adds hooks to Claude Code and Codex and links a Pi extension. Then
start `codex`, type `/hooks` and approve the four rex-restore entries, and open new panes.
`./scripts/uninstall.sh` does not remove either; each README says how.

## 🎨 Themes and Customization

The configuration uses Atom One Dark theme across all tools for a consistent experience. To modify the theme:

- **Neovim**: Edit `config/nvim/lua/plugins/onedark.lua`
- **Tmux**: Modify color variables in `tmux.conf`
- **Herdr**: Modify keybindings in `config/herdr/config.toml`
- **Rex**: Modify keybindings in `config/rex/init.lua`, then run `rex config reload`.
  Caps Lock is remapped to Control in macOS, so its `ctrl+...` bindings are Caps Lock+...
- **Starship**: Change themes with `./scripts/switch_starship_theme.sh`

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.


