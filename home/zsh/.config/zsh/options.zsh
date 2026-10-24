# History, directory navigation and line-editor keys.

# History is shared with new shells via the history file, without immediately
# injecting other tmux panes' commands into the active shell history.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_REDUCE_BLANKS INC_APPEND_HISTORY

# Type a directory (or ~named-dir) to cd into it.
setopt AUTO_CD CDABLE_VARS

# Vi editing in zsh itself is off; uncomment to enable.
# bindkey -v

# Up/Down browse history; inside multi-line commands they move between lines.
for keymap in viins vicmd emacs; do
  bindkey -M "$keymap" '^[[A' up-line-or-history
  bindkey -M "$keymap" '^[[B' down-line-or-history
  bindkey -M "$keymap" '^[OA' up-line-or-history
  bindkey -M "$keymap" '^[OB' down-line-or-history
done

# Ctrl+X Ctrl+E: edit the command line in $EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
for keymap in viins vicmd emacs; do
  bindkey -M "$keymap" '^X^E' edit-command-line
done
unset keymap

# fzf: Ctrl+R fuzzy history, Ctrl+T files, Alt+C directories.
(( $+commands[fzf] )) && source <(fzf --zsh)
