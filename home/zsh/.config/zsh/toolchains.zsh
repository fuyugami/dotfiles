# Language toolchains and CLI helpers. Each block is skipped if not installed.

# Node.js — nvm (installed by `install.sh node` into ~/.nvm)
[[ -s $NVM_DIR/nvm.sh ]] && source "$NVM_DIR/nvm.sh"
[[ -s $NVM_DIR/bash_completion ]] && source "$NVM_DIR/bash_completion"

# Python — Miniforge (conda + mamba) in ~/miniforge3. This replaces the blocks
# `conda init` / `mamba shell init` write; don't run those against ~/.zshrc.
if [[ -x $HOME/miniforge3/bin/conda ]]; then
  eval "$("$HOME/miniforge3/bin/conda" shell.zsh hook 2>/dev/null)"
  if [[ -x $HOME/miniforge3/bin/mamba ]]; then
    export MAMBA_EXE="$HOME/miniforge3/bin/mamba"
    export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
    eval "$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
  fi
fi

# zoxide: `z <part-of-path>` jumps to frequently used directories.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
