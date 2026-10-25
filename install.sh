#!/usr/bin/env bash
# Set up this machine (macOS or Linux) from ~/dotfiles.
#
#   ./install.sh                 run every step, in order
#   ./install.sh node go         run only these steps
#   ./install.sh doctor          check links and tools
#
# Every step is idempotent: re-running only does what is missing.
set -eo pipefail
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES
. "$DOTFILES/setup/lib.sh"

STEPS=(packages link git shell tmux node python go latex docker agents)

usage() {
  cat <<USAGE
Usage: ./install.sh [step ...]

Steps (default: all, in this order):
  packages   Homebrew + Brewfiles (Linux: apt/dnf base packages first)
  link       symlink home/* into \$HOME with Stow (backs up existing files)
  git        git identity in ~/.config/git/config.local (untracked)
  shell      zsh as login shell
  tmux       tmux plugins (resurrect, continuum)
  node       nvm, Node LTS as default, global npm packages (packages/npm.txt)
  python     uv, Miniforge (conda/mamba) and packages/conda/*.yml envs
  go         Go from go.dev + tools from packages/go.txt (GO_UPDATE=1 to upgrade)
  latex      TeX Live (MacTeX on macOS) if missing, Skim sync with Neovim
  docker     macOS: Colima; Linux: Docker Engine
  agents     Claude Code + Codex CLIs, Codex config seed
  doctor     check links and tools
USAGE
}

case "${1:-}" in -h|--help) usage; exit 0 ;; esac
[ "$OS" != unknown ] || die "unsupported OS: $(uname -s)"

[ $# -gt 0 ] || set -- "${STEPS[@]}"
for step in "$@"; do
  [ -f "$DOTFILES/setup/$step.sh" ] && [ "$step" != lib ] || { usage; die "unknown step: $step"; }
  info "[$step]"
  bash "$DOTFILES/setup/$step.sh"
done
