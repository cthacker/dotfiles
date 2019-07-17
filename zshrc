#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export PATH="/home/cameron/.pyenv/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi 

# Customize to your needs...
alias gla='git log --pretty=oneline --abbrev-commit'
alias vim='nvim'
ulimit -n 2048
alias dockerclean='docker rmi $(docker images -f "dangling=true" -q); docker volume rm $(docker volume ls -qf dangling=true)'
alias ls='ls --color=auto'

# make it so cd ..<TAB> completes to cd ../ like it should
zstyle ':completion:*' special-dirs true

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/cameron/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/home/cameron/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/cameron/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/cameron/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
 o

