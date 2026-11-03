#!/usr/bin/env bash
# Step (optional): install the Ghostty terminal app. macOS: Homebrew cask. Linux
# has no apt/dnf package, so install it from https://ghostty.org/docs/install/binary
# on a desktop; servers don't need it. Its config (home/ghostty) is linked by the
# link step on every machine, whether or not the app is installed.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

if [ "$OS" != macos ]; then
  ok "ghostty: not installed by this setup on Linux (desktops: ghostty.org/docs/install; servers: not needed)"
  exit 0
fi
load_brew || die "Homebrew is missing: run ./install.sh packages"

if brew list --cask ghostty >/dev/null 2>&1 || [ -d /Applications/Ghostty.app ]; then
  ok "ghostty already installed"
else
  info "Installing Ghostty"
  brew install --cask ghostty
  ok "ghostty"
fi
