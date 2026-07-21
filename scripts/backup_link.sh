#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup"

echo "$(tput setaf 79)Backing up existing dotfiles to $BACKUP_DIR$(tput sgr 0)"
echo "Dotfiles directory: $DOTFILES_DIR"
mkdir -p "$BACKUP_DIR"

# Back up an existing path once, then replace it with a symlink. Re-running the
# installer is safe: links that already point into this checkout are left alone,
# and a newer user-owned file is never overwritten when a backup already exists.
link_managed_path() {
  local source_path=$1
  local target_path=$2
  local backup_relative=$3
  local backup_path="$BACKUP_DIR/$backup_relative"

  if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
    echo "$(tput setaf 197)Skipping $target_path: source does not exist at $source_path$(tput sgr 0)"
    return
  fi

  if [ -L "$target_path" ] && [ "$target_path" -ef "$source_path" ]; then
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
      echo "$(tput setaf 197)Skipping $target_path: backup already exists at $backup_path$(tput sgr 0)"
      return
    fi

    echo "Backing up $target_path"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target_path" "$backup_path"
  fi

  echo "$(tput setaf 79)Creating symlink for $target_path$(tput sgr 0)"
  mkdir -p "$(dirname "$target_path")"
  ln -snf "$source_path" "$target_path"
}

echo "$(tput setaf 79)Creating symlinks in your home directory$(tput sgr 0)"

link_managed_path "$DOTFILES_DIR/vimrc" "$HOME/.vimrc" "vimrc"
link_managed_path "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc" "zshrc"
link_managed_path "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf" "tmux.conf"

# Link Neovim one top-level entry at a time. This preserves unrelated files in
# ~/.config/nvim and gives uninstall an exact set of managed paths to remove.
for config_path in "$DOTFILES_DIR"/config/nvim/*; do
  if [ -e "$config_path" ]; then
    config_name="$(basename "$config_path")"
    link_managed_path \
      "$config_path" \
      "$HOME/.config/nvim/$config_name" \
      "config/nvim/$config_name"
  fi
done

link_managed_path \
  "$DOTFILES_DIR/config/starship/starship.toml" \
  "$HOME/.config/starship.toml" \
  "config/starship.toml"

link_managed_path \
  "$DOTFILES_DIR/config/herdr/config.toml" \
  "$HOME/.config/herdr/config.toml" \
  "config/herdr/config.toml"

link_managed_path \
  "$DOTFILES_DIR/config/agents/skills/bro" \
  "$HOME/.agents/skills/bro" \
  "agents/skills/bro"
