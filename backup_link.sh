#!/usr/bin/env bash
echo "$(tput setaf 79)Backing up existing dotfiles to ~/.dotfiles_backup$(tput sgr 0)"

if [ -d "$HOME/.dotfiles_backup/" ] 
then
    echo "$(tput setaf 197)Backup already exists cannot overwrite$(tput sgr 0)"

else
    mkdir -p ${HOME}/.dotfiles_backup
    
    # array of files we backup
    declare -a all_files=(config/nvim vim vimrc bashrc bash_profile gitconfig zshrc zprofile zpreztorc)

    declare -a symlink_files=(vim vimrc bashrc bash_profile gitconfig zshrc zprofile zpreztorc)
    
    # loop through files that we backup and move to backup folder
    for i in ${all_files[@]}
    do
      mv ~/.$i ~/.dotfiles_backup/
       # or do whatever with individual element of the array
    done
    
    # create symlinks to the dotfiles
    echo "$(tput setaf 79)Creating symlinks in your home directory$(tput sgr 0)"
    
    for i in ${symlink_files[@]}
    do
      ln -snf $PWD/$i ~/.$i
    done

    if [ ! -d $HOME/.config/nvim ]; then
      echo "$(tput setaf 79)Creating ~/.config/nvim$(tput sgr 0)"
      mkdir -p $HOME/.config/nvim
    fi

    for config in $PWD/config/nvim/*; do
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
fi    
