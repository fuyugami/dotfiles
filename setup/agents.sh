#!/usr/bin/env bash
# Step: Claude Code + Codex CLIs. Claude's settings are linked by the link step;
# ~/.codex/config.toml is seeded once from setup/templates/ (Codex keeps editing it).
set -eo pipefail
. "$(dirname "$0")/lib.sh"

if ! has claude && [ ! -x "$HOME/.local/bin/claude" ]; then
  info "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi
ok "claude"

# macOS gets Codex from the cask in packages/Brewfile.macos.
if [ "$OS" = linux ] && ! has codex; then
  load_nvm || die "nvm is missing: run ./install.sh node"
  info "npm install -g @openai/codex"
  npm install -g --silent @openai/codex
fi
ok "codex"

if [ ! -f "$HOME/.codex/config.toml" ]; then
  mkdir -p "$HOME/.codex"
  cp "$DOTFILES/setup/templates/codex/config.toml" "$HOME/.codex/config.toml"
  ok "seeded ~/.codex/config.toml"
fi
