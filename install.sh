#!/bin/bash
echo Backing up existing dotfiles to ~/.dotfiles_backup

if [ -d "$HOME/.dotfiles_backup/" ] 
then
    echo Backup already exists cannot overwrite

else
    mkdir -p ${HOME}/.dotfiles_backup
    
    # array of files we backup
    declare -a files=(vim vimrc bashrc bash_profile gitconfig zshrc zprofile)
    
    # loop through files that we backup and move to backup folder
    for i in ${files[@]}
    do
      mv ~/.$i ~/.dotfiles_backup/
       # or do whatever with individual element of the array
    done
    
    # create symlinks to the dotfiles
    echo Creating symlinks in your home directory 
    
    for i in ${files[@]}
    do
      ln -snf $PWD/$i ~/.$i
    done
fi    
