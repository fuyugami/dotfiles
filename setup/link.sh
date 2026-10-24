#!/usr/bin/env bash
# Step: symlink home/<package> into $HOME with GNU Stow.
# Real files already at a target are moved to ~/.dotfiles-backup/<time>/ first.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

# Folded: Stow may link a whole directory (new files land in the repo).
FOLDED=(nvim tmux ghostty zsh)
# Per-file: the target directory also holds machine-local files
# (git/config.local, Claude state, other ~/.local/bin tools).
PER_FILE=(git claude conda bin)

has stow || load_brew || true
has stow || die "stow is missing: run ./install.sh packages"

for pkg in "${FOLDED[@]}" "${PER_FILE[@]}"; do
  (cd "$DOTFILES/home/$pkg" && find . \( -type f -o -type l \) ! -name .DS_Store) | while read -r rel; do
    rel="${rel#./}"
    target="$HOME/$rel"
    [ -e "$target" ] || [ -L "$target" ] || continue
    [ "$(readlink -f "$target")" = "$DOTFILES/home/$pkg/$rel" ] && continue
    backup "$target"
  done
done

stow --dir="$DOTFILES/home" --target="$HOME" --restow "${FOLDED[@]}"
stow --dir="$DOTFILES/home" --target="$HOME" --restow --no-folding "${PER_FILE[@]}"
ok "linked: ${FOLDED[*]} ${PER_FILE[*]}"
