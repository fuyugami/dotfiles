#!/usr/bin/env bash
# Step: nvm + Node LTS as default + global npm packages (packages/npm.txt).
set -eo pipefail
. "$(dirname "$0")/lib.sh"

NVM_VERSION=v0.40.8
NODE_VERSION=24

if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  info "Installing nvm $NVM_VERSION"
  git clone --quiet --depth 1 --branch "$NVM_VERSION" https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
fi
load_nvm

set +e
nvm ls "$NODE_VERSION" >/dev/null 2>&1 || nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION" >/dev/null
nvm use default >/dev/null
set -e
ok "node $(node --version) (nvm default)"

read_list "$DOTFILES/packages/npm.txt" | while read -r pkg; do
  npm ls -g --depth=0 "$pkg" >/dev/null 2>&1 && continue
  info "npm install -g $pkg"
  npm install -g --silent "$pkg"
done
ok "global npm packages"
