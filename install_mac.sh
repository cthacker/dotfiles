brew install neovim
brew install ripgrep
pip3 install neovim
npm install -g neovim
brew tap caskroom/fonts
brew cask install font-hack-nerd-font
source backup_link.sh
nvim +PluginInstall +qall
nvim +UpdateRemotePlugins +qall
