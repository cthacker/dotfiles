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

# Customize to your needs...
alias gla='git log --pretty=oneline --abbrev-commit'
alias vim='nvim'
alias cat='bat'
ulimit -n 2048
alias dockerclean='docker rmi $(docker images -f "dangling=true" -q); docker volume rm $(docker volume ls -qf dangling=true)'
alias ls='ls --color=auto'
#alias ls='ls -G'

# make it so cd ..<TAB> completes to cd ../ like it should
zstyle ':completion:*' special-dirs true

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/cameron/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/home/cameron/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/cameron/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/cameron/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/cameron/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/cameron/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/cameron/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/cameron/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

