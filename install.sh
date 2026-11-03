#!/usr/bin/env bash
# Set up this machine (macOS or Linux) from ~/dotfiles.
#
#   ./install.sh setup           dotfiles + what the shell and Neovim config need
#   ./install.sh install         link + optional toolchains/apps (run setup first)
#   ./install.sh                 both: setup, then install
#   ./install.sh node go         run only these steps
#   ./install.sh doctor          check links and tools
#
# Every step is idempotent: re-running only does what is missing.
set -eo pipefail
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
export DOTFILES
. "$DOTFILES/setup/lib.sh"

SETUP_STEPS=(packages link git shell tmux node python tools)
INSTALL_STEPS=(link go latex docker agents ghostty)

usage() {
  cat <<USAGE
Usage: ./install.sh [setup | install | step ...]

setup (make setup): dotfiles + what the shell and Neovim config need
  packages   macOS: Homebrew + packages/Brewfile; Linux: apt/dnf (packages/apt.txt, dnf.txt)
  link       symlink home/* into \$HOME with Stow (backs up existing files)
  git        git identity in ~/.config/git/config.local (untracked)
  shell      zsh as login shell
  tmux       tmux plugins (resurrect, continuum)
  node       nvm, Node LTS as default, global npm packages (packages/npm.txt)
  python     uv, Miniforge (conda/mamba) and packages/conda/*.yml envs
  tools      Linux: tools apt/dnf lack or ship too old (Neovim, tree-sitter, lua-language-server,
             stylua, golangci-lint, kubectl, powerlevel10k) from their releases; TOOLS_UPDATE=1 to upgrade

install (make install): link + optional installs; expects setup to be done
  go         Go from go.dev + tools from packages/go.txt (GO_UPDATE=1 to upgrade)
  latex      TeX Live (MacTeX on macOS) if missing, Skim sync with Neovim
  docker     macOS: Colima; Linux: Docker Engine (get.docker.com)
  agents     Claude Code + Codex CLIs, Codex config seed
  ghostty    optional: the Ghostty terminal app (macOS cask; on Linux desktops install it yourself)

No arguments: setup, then install.
  doctor     check links and tools
USAGE
}

# Warn (don't stop) when `install` runs on a machine that never ran setup.
check_setup() {
  local missing=()
  if [ "$OS" = macos ]; then load_brew || missing+=("Homebrew"); fi
  has stow || missing+=("stow")
  [ -f "$HOME/.config/git/config.local" ] || missing+=("git identity")
  [ -s "$HOME/.nvm/nvm.sh" ] || missing+=("nvm")
  [ -x "$HOME/miniforge3/bin/conda" ] || missing+=("Miniforge")
  if [ ${#missing[@]} -gt 0 ]; then
    local list
    list="$(printf '%s, ' "${missing[@]}")"
    warn "setup looks incomplete (missing: ${list%, })"
    warn "run 'make setup' (./install.sh setup) first; continuing, but steps may fail"
  fi
}

case "${1:-}" in -h|--help) usage; exit 0 ;; esac
[ "$OS" != unknown ] || die "unsupported OS: $(uname -s)"

[ $# -gt 0 ] || set -- setup install

# Expand the groups; a step listed twice (link) runs once.
steps=()
add_step() {
  case " ${steps[*]} " in *" $1 "*) return ;; esac
  steps+=("$1")
}
for arg in "$@"; do
  case "$arg" in
    setup) for s in "${SETUP_STEPS[@]}"; do add_step "$s"; done ;;
    install)
      # With setup in the same run, setup goes first whatever the order.
      case " $* " in
        *" setup "*) for s in "${SETUP_STEPS[@]}"; do add_step "$s"; done ;;
        *) check_setup ;;
      esac
      for s in "${INSTALL_STEPS[@]}"; do add_step "$s"; done
      ;;
    *)
      [ -f "$DOTFILES/setup/$arg.sh" ] && [ "$arg" != lib ] || { usage; die "unknown step: $arg"; }
      add_step "$arg"
      ;;
  esac
done

# A failing step is reported and the remaining steps still run; under plain
# `set -e` one failure (often without its own message) silently ended the run.
failed=()
for step in "${steps[@]}"; do
  info "[$step]"
  status=0
  bash "$DOTFILES/setup/$step.sh" || status=$?
  if [ "$status" -ne 0 ]; then
    warn "[$step] failed (exit $status)"
    failed+=("$step")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  die "failed steps: ${failed[*]} (re-run with: ./install.sh ${failed[*]})"
fi
ok "done: ${steps[*]}"
