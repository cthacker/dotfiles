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

  # A symlink that already points somewhere inside this checkout is ours, even
  # when it is stale or dangling because a file moved. Replace it outright: it
  # is not user data, and backing it up would litter the backup directory with
  # broken links that uninstall would later try to restore.
  if [ -L "$target_path" ]; then
    case "$(readlink "$target_path")" in
      "$DOTFILES_DIR"/*)
        rm -f "$target_path"
        ;;
    esac
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

# Link one skill directory into both skill roots: ~/.agents/skills is read by
# Codex and pi, ~/.claude/skills by Claude Code.
#
# Links are always flat, one directory per skill, even for skills grouped under
# experimental/ in this repo. Discovery differs per tool — some recurse into
# subdirectories of a skill root and some do not — so a nested layout would load
# unevenly. The experimental/ grouping is a repo-side
# convention only; what lands in the skill roots looks identical either way.
link_skill() {
  local skill_path=$1
  local skill_name
  skill_name="$(basename "$skill_path")"

  link_managed_path \
    "$skill_path" \
    "$HOME/.agents/skills/$skill_name" \
    "agents/skills/$skill_name"

  link_managed_path \
    "$skill_path" \
    "$HOME/.claude/skills/$skill_name" \
    "claude/skills/$skill_name"
}

# Stable skills live at the top level; skills still being trialled live under
# experimental/ so they are easy to spot and remove. Both are linked the same way.
for skill_path in "$DOTFILES_DIR"/config/agents/skills/*/; do
  skill_path="${skill_path%/}"
  if [ ! -d "$skill_path" ] || [ "$(basename "$skill_path")" = "experimental" ]; then
    continue
  fi
  link_skill "$skill_path"
done

for skill_path in "$DOTFILES_DIR"/config/agents/skills/experimental/*/; do
  skill_path="${skill_path%/}"
  if [ ! -d "$skill_path" ]; then
    continue
  fi
  link_skill "$skill_path"
done

# Expose repo scripts as commands on PATH. ~/.local/bin is prepended to PATH by
# zshrc, and these are plain bash scripts, so they work from any shell.
link_managed_path \
  "$DOTFILES_DIR/scripts/update_ai.sh" \
  "$HOME/.local/bin/update-ai" \
  "local/bin/update-ai"
