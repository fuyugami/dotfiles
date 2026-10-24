#!/usr/bin/env bash
# Step: make the system zsh the login shell.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

if [ "$OS" = macos ]; then
  zsh_path=/bin/zsh
  current="$(dscl . -read "$HOME" UserShell | awk '{print $2}')"
else
  zsh_path="$(command -v zsh)" || die "zsh is missing: run ./install.sh packages"
  current="$(getent passwd "$USER" | cut -d: -f7)"
fi

if [ "$current" != "$zsh_path" ]; then
  grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$zsh_path"
fi
ok "login shell: $zsh_path"
