# Dotfiles Repository Guide

## Commands
- Install plugins: Automatically handled by Lazy.nvim on startup
- Install on macOS: `./install_mac.sh`
- Install on Linux: `./install_linux.sh`
- Install Starship: `./scripts/install_starship.sh`
- Switch Starship theme: `./scripts/switch_starship_theme.sh [theme_name]`
- Uninstall: `./uninstall.sh`

## Code Style Guidelines
- **Indentation**: 2-space tabs (4-space for Python/C++)
- **Line Length**: Max 100 characters
- **Naming**:
  - Functions: snake_case (e.g., `git_clean_branches`)
  - Variables: UPPERCASE for constants, lowercase for others
  - Aliases: Lowercase with descriptive names (Git: g-prefix)

## Editor Settings
- Vim/Neovim:
  - Leader key: Space
  - No swapfiles or backups
  - Unix line endings (LF)
  - Code syntax highlighting
  - File-specific formatting for Python/C++

## Bash Scripts
- Always start with `#!/bin/bash`
- Use `set -e` for error handling
- 2-space indentation
- Prefer absolute paths over relative paths

## Git Workflow
- Descriptive commit messages
- Use existing aliases for common operations
- Clean up merged branches with `gclean`