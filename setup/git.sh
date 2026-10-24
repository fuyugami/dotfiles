#!/usr/bin/env bash
# Step: git identity. Tracked config is home/git; name/email live only in
# ~/.config/git/config.local (untracked), taken from ~/.gitconfig or prompted.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

local_config="$HOME/.config/git/config.local"
if [ ! -f "$local_config" ]; then
  name="$(git config --file "$HOME/.gitconfig" user.name 2>/dev/null || true)"
  email="$(git config --file "$HOME/.gitconfig" user.email 2>/dev/null || true)"
  [ -n "$name" ] || read -r -p "git user.name: " name
  [ -n "$email" ] || read -r -p "git user.email: " email
  mkdir -p "$(dirname "$local_config")"
  git config --file "$local_config" user.name "$name"
  git config --file "$local_config" user.email "$email"
fi
ok "git identity: $(git config --file "$local_config" user.name) <$(git config --file "$local_config" user.email)>"

# Everything now lives in ~/.config/git; retire the legacy file.
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
  backup "$HOME/.gitconfig"
fi
