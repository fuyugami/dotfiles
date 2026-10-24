# Editor, named directories and aliases.

if (( $+commands[nvim] )); then
  export EDITOR=nvim
  export VISUAL=nvim
fi

# Named directories: `cd ~dev`, or just `~dev` with AUTO_CD.
hash -d home="$HOME"
hash -d work="$HOME/Workspace"
hash -d dev="$HOME/Workspace/DEV"
hash -d docs="$HOME/Documents"
hash -d dot="$HOME/dotfiles"

# Git (the few Oh My Zsh aliases in daily use)
alias gst='git status'
alias gaa='git add --all'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git pull'
alias gp='git push'
alias glog='git log --oneline --decorate --graph'
