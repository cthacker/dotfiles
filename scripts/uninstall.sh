#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup"

echo "$(tput setaf 79)Uninstalling dotfiles$(tput sgr 0)"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "$(tput setaf 197)No backup directory found at $BACKUP_DIR. Cannot uninstall.$(tput sgr 0)"
  exit 1
fi

# Remove only a symlink managed by this checkout, then restore its backup when
# the destination is clear. Real files and unrelated configuration are kept.
unlink_and_restore() {
  local source_path=$1
  local target_path=$2
  local backup_relative=$3
  local legacy_backup_relative=${4:-}
  local legacy_backup_path
  local link_destination
  local backup_path="$BACKUP_DIR/$backup_relative"

  if [ ! -e "$backup_path" ] && [ ! -L "$backup_path" ] \
      && [ -n "$legacy_backup_relative" ]; then
    legacy_backup_path="$BACKUP_DIR/$legacy_backup_relative"
    if [ -e "$legacy_backup_path" ] || [ -L "$legacy_backup_path" ]; then
      backup_path="$legacy_backup_path"
    fi
  fi

  if [ -L "$target_path" ]; then
    link_destination="$(readlink "$target_path")"
    if { [ -e "$source_path" ] && [ "$target_path" -ef "$source_path" ]; } \
        || [ "$link_destination" = "$source_path" ]; then
      echo "$(tput setaf 79)Removing symlink $target_path$(tput sgr 0)"
      rm -f "$target_path"
    fi
  fi

  if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
      echo "$(tput setaf 197)Skipping restore for $target_path: destination already exists$(tput sgr 0)"
      return
    fi

    echo "$(tput setaf 79)Restoring $target_path from backup$(tput sgr 0)"
    mkdir -p "$(dirname "$target_path")"
    cp -R "$backup_path" "$target_path"
  fi
}

unlink_and_restore "$DOTFILES_DIR/vim" "$HOME/.vim" "vim" ".vim"
unlink_and_restore "$DOTFILES_DIR/vimrc" "$HOME/.vimrc" "vimrc" ".vimrc"
unlink_and_restore "$DOTFILES_DIR/bashrc" "$HOME/.bashrc" "bashrc" ".bashrc"
unlink_and_restore "$DOTFILES_DIR/bash_profile" "$HOME/.bash_profile" "bash_profile" ".bash_profile"
unlink_and_restore "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig" "gitconfig" ".gitconfig"
unlink_and_restore "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc" "zshrc" ".zshrc"
unlink_and_restore "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf" "tmux.conf" ".tmux.conf"

for config_path in "$DOTFILES_DIR"/config/nvim/*; do
  if [ -e "$config_path" ]; then
    config_name="$(basename "$config_path")"
    unlink_and_restore \
      "$config_path" \
      "$HOME/.config/nvim/$config_name" \
      "config/nvim/$config_name"
  fi
done

# Compatibility with backups made by the previous installer, which moved the
# entire Neovim directory to ~/.dotfiles_backup/nvim.
if [ -d "$BACKUP_DIR/nvim" ]; then
  echo "$(tput setaf 79)Restoring legacy Neovim backup$(tput sgr 0)"
  mkdir -p "$HOME/.config/nvim"
  cp -R -n "$BACKUP_DIR/nvim/." "$HOME/.config/nvim/"
fi

unlink_and_restore \
  "$DOTFILES_DIR/config/starship/starship.toml" \
  "$HOME/.config/starship.toml" \
  "config/starship.toml"

unlink_and_restore \
  "$DOTFILES_DIR/config/herdr/config.toml" \
  "$HOME/.config/herdr/config.toml" \
  "config/herdr/config.toml"

unlink_and_restore \
  "$DOTFILES_DIR/config/agents/skills/bro" \
  "$HOME/.agents/skills/bro" \
  "agents/skills/bro"

echo "$(tput setaf 79)Uninstallation complete!$(tput sgr 0)"
echo "Your original dotfiles have been restored from $BACKUP_DIR when available."
echo "You may want to restart your terminal to apply changes."
