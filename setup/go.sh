#!/usr/bin/env bash
# Step: Go from the official go.dev tarball into /usr/local/go (macOS + Linux),
# then the tools in packages/go.txt into $GOPATH/bin.
# Re-runs skip what is installed; GO_UPDATE=1 upgrades Go and reinstalls tools.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

GOROOT_DIR=/usr/local/go

install_go() {
  local version os arch file sha tmp
  version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n 1)"
  if [ -x "$GOROOT_DIR/bin/go" ] && [ "$("$GOROOT_DIR/bin/go" env GOVERSION)" = "$version" ]; then
    ok "$version is current"
    return
  fi

  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$(uname -m)" in
    x86_64) arch=amd64 ;;
    arm64 | aarch64) arch=arm64 ;;
    *) die "unsupported CPU: $(uname -m)" ;;
  esac
  file="$version.$os-$arch.tar.gz"
  sha="$(curl -fsSL 'https://go.dev/dl/?mode=json' |
    awk -v f="\"$file\"" '$2 == f "," {found = 1} found && $1 == "\"sha256\":" {gsub(/[",]/, "", $2); print $2; exit}')"
  [ -n "$sha" ] || die "no checksum published for $file"

  info "Installing $version ($os/$arch) to $GOROOT_DIR"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/$file" "https://go.dev/dl/$file"
  if has sha256sum; then
    echo "$sha  $tmp/$file" | sha256sum -c - >/dev/null
  else
    echo "$sha  $tmp/$file" | shasum -a 256 -c - >/dev/null
  fi || die "checksum mismatch for $file"
  sudo rm -rf "$GOROOT_DIR"
  sudo tar -C "$(dirname "$GOROOT_DIR")" -xzf "$tmp/$file"
  rm -rf "$tmp"
  ok "$("$GOROOT_DIR/bin/go" version)"
}

if [ ! -x "$GOROOT_DIR/bin/go" ] || [ -n "${GO_UPDATE:-}" ]; then
  install_go
fi
export PATH="$GOROOT_DIR/bin:$PATH"
bin_dir="$(go env GOPATH)/bin"

read_list "$DOTFILES/packages/go.txt" | while read -r module; do
  name="${module##*/}"
  case "$name" in v[0-9]*) name="$(basename "$(dirname "$module")")" ;; esac
  if [ -z "${GO_UPDATE:-}" ] && [ -x "$bin_dir/$name" ]; then
    continue
  fi
  info "go install $module@latest"
  go install "$module@latest"
done
ok "go tools in $bin_dir"
