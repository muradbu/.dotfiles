# Lines configured by zsh-newuser-install
# gssg
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt extendedglob
setopt HIST_IGNORE_space
unsetopt beep
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/murad/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Enable colors
autoload -U colors && colors

# Change prompt
PROMPT="[%n@%M %~]$ "

# Environment variables
export EDITOR=nvim
export PATH="${PATH}:/home/murad/.local/bin"
## Use GBM as a backend, as EGLStreams is not supported by Sway
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GTK_THEME=Adwaita:dark

# Auto mount disks
#udiskie &

# Start nm-applet (NEEDED for ProtonVPN to work correctly)
# --no-agent disables desktop notifications
#nm-applet --no-agent &

# Aliases
alias vim='nvim'
alias svim='sudoedit'
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
