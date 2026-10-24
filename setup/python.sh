#!/usr/bin/env bash
# Step: uv (official installer, ~/.local/bin) and Miniforge (conda + mamba,
# conda-forge) in ~/miniforge3, plus the envs in packages/conda/*.yml.
# Existing envs are left as they are.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

if [ ! -x "$HOME/.local/bin/uv" ]; then
  info "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi
ok "$("$HOME/.local/bin/uv" --version) (update: uv self update)"

prefix="$HOME/miniforge3"
if [ ! -x "$prefix/bin/conda" ]; then
  info "Installing Miniforge"
  installer="$(mktemp)"
  curl -fsSL -o "$installer" \
    "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname -s)-$(uname -m).sh"
  bash "$installer" -b -p "$prefix"
  rm -f "$installer"
fi
conda="$prefix/bin/mamba"
[ -x "$conda" ] || conda="$prefix/bin/conda"

for env_file in "$DOTFILES"/packages/conda/*.yml; do
  name="$(sed -n 's/^name: *//p' "$env_file")"
  if "$prefix/bin/conda" env list | awk '{print $1}' | grep -qx "$name"; then
    ok "conda env $name (exists; update with: conda env update -n $name -f $env_file)"
  else
    info "Creating conda env $name"
    "$conda" env create -y -f "$env_file"
  fi
done
ok "miniforge in $prefix"
