## TODO
This doesn't quite work, need to add submodules or something

##Who doesn't love some dotfiles

Since I have spent **far** too many hours playing with this kind of stuff and using dropbox, I
figured why not take it a step further and spend some more time putting this on github.

Installing these dotfiles is a reversible process aided by quick and easy install and uninstall
scripts.

## Installation

Installation is a super easy process. 

1. clone repo  `git clone git@github.com:/cthacker/dotfiles.git`
2. `cd dotfiles/`
3. `./install.sh`
4. `git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim`
5. open vim and type `:PluginInstall`
6. cd into youcompleteme folder and compile using
  - ./install.py --clang-completer --tern-completer --gocode-completer

## Unistall

If you want to remove them, use the uninstall script and the backups will be made current again

`./uninstall.sh`




