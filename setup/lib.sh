# shellcheck shell=bash disable=SC2034  # variables here are used by the sourcing steps
# Shared helpers, sourced by every setup/*.sh step. Bash 3.2 compatible (macOS).

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux) OS=linux ;;
  *) OS=unknown ;;
esac
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

# Put Homebrew on PATH for this process (a fresh machine has no shell env yet).
load_brew() {
  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$brew_bin" ]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done
  return 1
}

# Load nvm into this process. nvm.sh is not `set -e` safe.
load_nvm() {
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] || return 1
  set +e
  . "$NVM_DIR/nvm.sh"
  set -e
}

# Print a package list: one entry per line; blank lines and # comments ignored.
read_list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# Move an existing file out of the way, keeping its path under $BACKUP_DIR.
backup() {
  local rel="${1#"$HOME"/}"
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$1" "$BACKUP_DIR/$rel"
  warn "moved existing ~/$rel to $BACKUP_DIR/$rel"
}
