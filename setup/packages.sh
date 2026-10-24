#!/usr/bin/env bash
# Step: system packages.
#   macOS: Xcode Command Line Tools, Homebrew, packages/Brewfile + Brewfile.macos
#   Linux: base packages (apt or dnf), Homebrew on Linux, packages/Brewfile
set -eo pipefail
. "$(dirname "$0")/lib.sh"

if [ "$OS" = macos ]; then
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    die "finish installing the Command Line Tools, then re-run ./install.sh"
  fi
elif has apt-get; then
  info "apt: base packages"
  sudo apt-get update -q
  read_list "$DOTFILES/packages/apt.txt" | xargs sudo apt-get install -y -q
elif has dnf; then
  info "dnf: base packages"
  read_list "$DOTFILES/packages/dnf.txt" | xargs sudo dnf install -y
else
  die "unsupported system: need macOS, apt or dnf"
fi

if ! load_brew; then
  info "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew || die "Homebrew was installed but brew is not found"
fi

info "brew bundle: packages/Brewfile"
brew bundle --no-upgrade --file="$DOTFILES/packages/Brewfile"
if [ "$OS" = macos ]; then
  info "brew bundle: packages/Brewfile.macos"
  brew bundle --no-upgrade --file="$DOTFILES/packages/Brewfile.macos"
fi
