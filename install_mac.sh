
# install to system
# need to have node installed and python3 (better use pyenv)
brew install neovim
brew install ripgrep
brew install tmux
brew install node
brew install yarn
brew tap caskroom/fonts
brew cask install font-hack-nerd-font font-firacode-nerd-font font-droidsansmono-nerd-font

pip3 install neovim
npm install -g neovim

curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# backup dotfiles
source backup_link.sh
# install nvim plugins
echo "Installation success"
echo "Run nvim and do :PluginInstall"
