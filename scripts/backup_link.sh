#!/usr/bin/env bash
echo "$(tput setaf 79)Backing up existing dotfiles to ~/.dotfiles_backup$(tput sgr 0)"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Dotfiles directory: $DOTFILES_DIR"

if [ -d "$HOME/.dotfiles_backup/" ]
then
    echo "$(tput setaf 197)Backup already exists cannot overwrite$(tput sgr 0)"

else
    mkdir -p ${HOME}/.dotfiles_backup

    # array of files we backup
    declare -a all_files=(config/nvim vim vimrc bashrc bash_profile gitconfig zsh/zshrc config/starship tmux.conf)

    declare -a symlink_files=(vim vimrc bashrc bash_profile gitconfig)
    declare -a zsh_files=(zsh/zshrc)

    # loop through files that we backup and move to backup folder
    for i in ${all_files[@]}
    do
      # Extract the basename for the destination path
      file_basename=$(basename $i)
      
      # Special case for zsh files which are now in a subdirectory
      if [[ $i == zsh/* ]]; then
        if [ -f ~/.$file_basename ]; then
          echo "Backing up ~/.$file_basename"
          mv ~/.$file_basename ~/.dotfiles_backup/
        fi
      else
        if [ -f ~/.$i ] || [ -d ~/.$i ]; then
          echo "Backing up ~/.$i"
          mv ~/.$i ~/.dotfiles_backup/
        fi
      fi
    done

    # create symlinks to the dotfiles
    echo "$(tput setaf 79)Creating symlinks in your home directory$(tput sgr 0)"

    for i in ${symlink_files[@]}
    do
      ln -snf $DOTFILES_DIR/$i ~/.$i
    done

    # Create symlinks for zsh files
    for i in ${zsh_files[@]}
    do
      file_basename=$(basename $i)
      ln -snf $DOTFILES_DIR/$i ~/.$file_basename
    done

    # Handle Neovim config
    if [ ! -d $HOME/.config/nvim ]; then
      echo "$(tput setaf 79)Creating ~/.config/nvim$(tput sgr 0)"
      mkdir -p $HOME/.config/nvim
    fi

    for config in $DOTFILES_DIR/config/nvim/*; do
      target=$HOME/.config/nvim/$( basename $config )
      echo ${config}
      echo ${target}
      if [ -e $target ]; then
        echo "$(tput setaf 245)~${target#$HOME} already exists ... skipping$(tput sgr 0)"
      else
        echo "$(tput setaf 79)Creating symlink for ${config}$(tput sgr 0)"
        ln -snf $config $target
      fi
    done

    # Starship configuration
    if [ ! -d $HOME/.config ]; then
      echo "$(tput setaf 79)Creating ~/.config$(tput sgr 0)"
      mkdir -p $HOME/.config
    fi

    if [ -f $DOTFILES_DIR/config/starship/starship.toml ]; then
      echo "$(tput setaf 79)Creating symlink for Starship configuration$(tput sgr 0)"
      ln -snf $DOTFILES_DIR/config/starship/starship.toml $HOME/.config/starship.toml
    fi

    # Tmux configuration
    ln -snf $DOTFILES_DIR/tmux.conf $HOME/.tmux.conf
fi
