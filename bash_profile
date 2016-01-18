#set colors
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# Set architecture flags
export ARCHFLAGS="-arch x86_64"
#Ensure user-installed binaries take precendence
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH=/usr/texbin:$PATH
#For Go
export PATH=$PATH:/usr/local/opt/go/libexec/bin

#Load .bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ -f $(brew --prefix)/etc/bash_completion ]; then
        . $(brew --prefix)/etc/bash_completion
fi


