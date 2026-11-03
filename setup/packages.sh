#!/usr/bin/env bash
# Step: system packages.
#   macOS: Xcode Command Line Tools, Homebrew, packages/Brewfile
#   Linux: apt (Debian, Ubuntu) or dnf (Fedora): packages/apt.txt / dnf.txt.
#          Tools the distro lacks or ships too old: `install.sh tools`.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

# Install a package list; a name the distro does not carry is skipped with a
# warning instead of failing the whole step.
install_apt() {
  local pkg min candidate available=()
  info "apt: packages/apt.txt"
  sudo apt-get update -q
  while read -r pkg; do
    min=""
    case "$pkg" in *">="*) min="${pkg#*>=}" pkg="${pkg%%>=*}" ;; esac
    candidate="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}')"
    if [ -z "$candidate" ] || [ "$candidate" = "(none)" ]; then
      warn "apt has no '$pkg' on this release: skipped"
    elif [ -n "$min" ] && ! dpkg --compare-versions "$candidate" ge "$min"; then
      warn "apt's $pkg $candidate is older than $min: skipped (install.sh tools downloads it)"
    else
      available+=("$pkg")
    fi
  done < <(read_list "$DOTFILES/packages/apt.txt")
  sudo apt-get install -y -q "${available[@]}"
}

install_dnf() {
  local pkgs=()
  info "dnf: packages/dnf.txt"
  while read -r pkg; do pkgs+=("$pkg"); done < <(read_list "$DOTFILES/packages/dnf.txt")
  # strict=0: skip names this release lacks instead of aborting.
  sudo dnf install -y --setopt=strict=0 "${pkgs[@]}"
}

if [ "$OS" = macos ]; then
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    die "finish installing the Command Line Tools, then re-run ./install.sh"
  fi
  if ! load_brew; then
    info "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew || die "Homebrew was installed but brew is not found"
  fi
  info "brew bundle: packages/Brewfile"
  brew bundle --no-upgrade --file="$DOTFILES/packages/Brewfile"
elif has apt-get; then
  install_apt
elif has dnf; then
  install_dnf
else
  die "unsupported system: need macOS, apt (Debian, Ubuntu) or dnf (Fedora)"
fi
ok "packages"
