#!/usr/bin/env bash
set -e

echo "$(tput setaf 79)Uninstalling dotfiles$(tput sgr 0)"

# Check if backup directory exists
if [ ! -d "$HOME/.dotfiles_backup/" ]; then
    echo "$(tput setaf 197)No backup directory found at ~/.dotfiles_backup. Cannot uninstall.$(tput sgr 0)"
    exit 1
fi

# array of files to restore from backup
declare -a all_files=(
    "vimrc" 
    "vim" 
    "bashrc" 
    "bash_profile" 
    "gitconfig" 
    "zshrc" 
    "config/nvim"
)

# Remove symlinks and restore from backup if available
for i in "${all_files[@]}"; do
    # Remove symlink
    if [ -L "$HOME/.$i" ]; then
        echo "$(tput setaf 79)Removing symlink ~/.$i$(tput sgr 0)"
        rm -f "$HOME/.$i"
    elif [ -d "$HOME/.$i" ]; then
        echo "$(tput setaf 79)Removing directory ~/.$i$(tput sgr 0)"
        rm -rf "$HOME/.$i"
    fi

    # Restore from backup
    if [ -e "$HOME/.dotfiles_backup/$i" ] || [ -d "$HOME/.dotfiles_backup/$i" ]; then
        echo "$(tput setaf 79)Restoring ~/.$i from backup$(tput sgr 0)"
        cp -R "$HOME/.dotfiles_backup/$i" "$HOME/.$i"
    fi
done

# Handle tmux configuration
if [ -L "$HOME/.tmux.conf" ]; then
    echo "$(tput setaf 79)Removing tmux configuration symlink$(tput sgr 0)"
    rm -f "$HOME/.tmux.conf"
    
    if [ -e "$HOME/.dotfiles_backup/tmux.conf" ]; then
        echo "$(tput setaf 79)Restoring tmux configuration from backup$(tput sgr 0)"
        cp "$HOME/.dotfiles_backup/tmux.conf" "$HOME/.tmux.conf"
    fi
fi

# Handle Starship configuration
if [ -L "$HOME/.config/starship.toml" ]; then
    echo "$(tput setaf 79)Removing Starship configuration symlink$(tput sgr 0)"
    rm -f "$HOME/.config/starship.toml"
fi

# Handle Herdr configuration without disturbing its runtime state.
if [ -L "$HOME/.config/herdr/config.toml" ]; then
    echo "$(tput setaf 79)Removing Herdr configuration symlink$(tput sgr 0)"
    rm -f "$HOME/.config/herdr/config.toml"
fi

if [ -f "$HOME/.dotfiles_backup/config/herdr/config.toml" ]; then
    echo "$(tput setaf 79)Restoring Herdr configuration from backup$(tput sgr 0)"
    mkdir -p "$HOME/.config/herdr"
    cp "$HOME/.dotfiles_backup/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
fi

# Handle the global bro skill.
if [ -L "$HOME/.agents/skills/bro" ]; then
    echo "$(tput setaf 79)Removing global bro skill symlink$(tput sgr 0)"
    rm -f "$HOME/.agents/skills/bro"
fi

if [ -e "$HOME/.dotfiles_backup/agents/skills/bro" ]; then
    echo "$(tput setaf 79)Restoring global bro skill from backup$(tput sgr 0)"
    mkdir -p "$HOME/.agents/skills"
    cp -R "$HOME/.dotfiles_backup/agents/skills/bro" "$HOME/.agents/skills/bro"
fi

echo "$(tput setaf 79)Uninstallation complete!$(tput sgr 0)"
echo "$(tput setaf 79)Your original dotfiles have been restored from ~/.dotfiles_backup/$(tput sgr 0)"
echo "$(tput setaf 79)You may want to restart your terminal to apply changes.$(tput sgr 0)"


