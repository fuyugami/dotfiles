#!/usr/bin/env bash
# Check that every tracked file is linked and the expected tools are on PATH.
set -eo pipefail
. "$(dirname "$0")/lib.sh"
load_brew || true
load_nvm || true
problems=0

info "Links"
for pkg_dir in "$DOTFILES"/home/*/; do
  pkg="$(basename "$pkg_dir")"
  broken="$(cd "$pkg_dir" && find . \( -type f -o -type l \) ! -name .DS_Store | while read -r rel; do
    rel="${rel#./}"
    [ "$(readlink -f "$HOME/$rel" 2>/dev/null)" = "$DOTFILES/home/$pkg/$rel" ] || echo "$HOME/$rel"
  done)"
  if [ -z "$broken" ]; then ok "$pkg"; else warn "$pkg not linked: $broken"; problems=$((problems + 1)); fi
done

info "Tools"
tools="brew stow git zsh tmux nvim rg fd fzf node npm go conda uv docker claude codex"
for tool in $tools; do
  if has "$tool" || { [ "$tool" = conda ] && [ -x "$HOME/miniforge3/bin/conda" ]; }; then
    ok "$tool"
  else
    warn "$tool missing"
    problems=$((problems + 1))
  fi
done

info "tmux plugins"
if [ -x "$HOME/.local/share/tmux/plugins/tpm/tpm" ]; then
  ok "tpm, resurrect, continuum"
else
  warn "tmux plugins missing: run ./install.sh tmux"
  problems=$((problems + 1))
fi

info "Identity"
if git config --file "$HOME/.config/git/config.local" user.email >/dev/null 2>&1; then
  ok "git identity in ~/.config/git/config.local"
else
  warn "no git identity: run ./install.sh git"
  problems=$((problems + 1))
fi

if [ "$problems" -gt 0 ]; then
  warn "$problems problem(s)"
  exit 1
fi
ok "all good"
