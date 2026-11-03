#!/usr/bin/env bash
# Check that every tracked file is linked and the expected tools are on PATH.
set -eo pipefail
. "$(dirname "$0")/lib.sh"
load_brew || true
load_nvm || true
# The tool dirs ~/.zprofile adds, so doctor works from any shell (even a fresh one).
PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$HOME/miniforge3/condabin:$PATH"
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
tools="stow git zsh tmux nvim rg fd fzf node npm go conda uv tree-sitter lua-language-server stylua latexmk texlab docker claude codex"
[ "$OS" != macos ] || tools="brew $tools"
for tool in $tools; do
  if has "$tool"; then
    ok "$tool"
  else
    warn "$tool missing"
    problems=$((problems + 1))
  fi
done

info "Python"
conda_bin="$HOME/miniforge3/bin/conda"
if [ -x "$conda_bin" ]; then
  envs="$("$conda_bin" env list | awk '!/^#/ {print $1}')"
  for env_file in "$DOTFILES"/packages/conda/*.yml; do
    name="$(sed -n 's/^name: *//p' "$env_file")"
    if printf '%s\n' "$envs" | grep -qx "$name"; then
      ok "conda env $name: $("$HOME/miniforge3/envs/$name/bin/python" --version 2>&1)"
    else
      warn "conda env $name missing: run ./install.sh python"
      problems=$((problems + 1))
    fi
  done
else
  warn "Miniforge missing: run ./install.sh python"
  problems=$((problems + 1))
fi

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
