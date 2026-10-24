#!/usr/bin/env bash
# Step: tmux plugins into ~/.local/share/tmux/plugins: TPM plus every
# `set -g @plugin` line in tmux.conf (resurrect, continuum).
set -eo pipefail
. "$(dirname "$0")/lib.sh"

PLUGINS="$HOME/.local/share/tmux/plugins"

sed -n "s/^set -g @plugin '\(.*\)'$/\1/p" "$DOTFILES/home/tmux/.config/tmux/tmux.conf" | while read -r repo; do
  dir="$PLUGINS/${repo##*/}"
  if [ ! -d "$dir" ]; then
    info "Installing $repo"
    git clone -q --depth 1 "https://github.com/$repo" "$dir"
  fi
done
ok "tmux plugins in $PLUGINS"
