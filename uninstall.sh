#!/bin/bash

# array of files we backup
declare -a files=(.config/nvm .vim .vimrc .bashrc .bash_profile .gitconfig .zshrc .zprofile
.zpreztorc)

if [ -d "$HOME/.dotfiles_backup/" ] 
then
    echo "Restoring previously backed up dotfiles from ~/.dotfiles_backup"

    # remove symlinks to the dotfiles
    echo "Removing symlinks in your home directory"
    
    for i in ${files[@]}
    do
      rm -rf $HOME/$i
    done 
    
    # loop through files that we backup and move to home folder
    echo 
    for i in ${files[@]}
    do
      mv ~/.dotfiles_backup/$i ~/$i
    done
    
    # finally delete backup folder
    rm -rf ~/.dotfiles_backup
                              
else
    echo "Why you tryin'na uninstall when you haven't installed"
    echo "First run the install script"
fi


