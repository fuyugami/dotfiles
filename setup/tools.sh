#!/usr/bin/env bash
# Step (Linux): tools apt/dnf lack or ship too old, from their official releases
# into ~/.local/opt and ~/.local/bin (on PATH via ~/.zprofile). Each tool is
# installed only when missing or below the version this setup needs, so Fedora,
# whose repos are current, skips most of them. Downloads are verified against the
# sha256 that GitHub publishes for every release asset.
#   TOOLS_UPDATE=1 ./install.sh tools    reinstall all of them at the latest release
#   GITHUB_TOKEN=...                     avoids GitHub API rate limits
# macOS gets all of these from Homebrew (packages/Brewfile).
set -eo pipefail
. "$(dirname "$0")/lib.sh"

if [ "$OS" != linux ]; then
  ok "tools: macOS installs these with Homebrew (packages/Brewfile)"
  exit 0
fi

OPT="$HOME/.local/opt"
BIN="$HOME/.local/bin"
mkdir -p "$OPT" "$BIN"
export PATH="$BIN:$PATH"

case "$(uname -m)" in
  x86_64) NVIM_ARCH=x86_64 LUA_ARCH=x64 STYLUA_ARCH=x86_64 GOLANGCI_ARCH=amd64 TEXLAB_ARCH=x86_64 TS_ARCH=x64 K8S_ARCH=amd64 ;;
  aarch64 | arm64) NVIM_ARCH=arm64 LUA_ARCH=arm64 STYLUA_ARCH=aarch64 GOLANGCI_ARCH=arm64 TEXLAB_ARCH=aarch64 TS_ARCH=arm64 K8S_ARCH=arm64 ;;
  *) die "unsupported CPU: $(uname -m)" ;;
esac

# Versions the setup needs (floors): Neovim config targets 0.12; nvim-treesitter's
# main branch needs tree-sitter-cli 0.26.1 or later.
NVIM_MIN=0.12
TREE_SITTER_MIN=0.26.1

# ver_ge A B: A >= B.
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n 1)" = "$2" ]; }

# need NAME [INSTALLED_VERSION MIN]: should NAME be (re)installed?
need() {
  [ -z "${TOOLS_UPDATE:-}" ] || return 0
  has "$1" || return 0
  [ -n "${3:-}" ] && ! ver_ge "$2" "$3"
}

# fetch REPO ASSET DEST: download a release asset ("@TAG@"/"@VER@" in ASSET are
# replaced) and verify its sha256. Sets FETCHED_TAG.
fetch() {
  local repo="$1" asset="$2" dest="$3" json ver url digest line
  json="$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/$repo/releases/latest")" || die "cannot read the $repo release (GitHub rate limit? set GITHUB_TOKEN)"
  FETCHED_TAG="$(jq -r .tag_name <<<"$json")"
  ver="${FETCHED_TAG#v}"
  asset="${asset//@TAG@/$FETCHED_TAG}"
  asset="${asset//@VER@/$ver}"
  line="$(jq -r --arg n "$asset" '.assets[] | select(.name == $n) | "\(.browser_download_url) \(.digest // "")"' <<<"$json")"
  [ -n "$line" ] || die "$repo $FETCHED_TAG has no asset $asset"
  url="${line%% *}"
  digest="${line#* }"
  info "Downloading $repo $FETCHED_TAG ($asset)"
  curl -fsSL -o "$dest" "$url"
  verify "$dest" "${digest#sha256:}" "$asset"
}

# verify FILE SHA256 LABEL
verify() {
  local actual
  if [ -z "$2" ]; then
    warn "no published checksum for $3: not verified"
    return 0
  fi
  actual="$(sha256sum "$1" | awk '{print $1}')"
  [ "$actual" = "$2" ] || die "checksum mismatch for $3"
}

# --- tools -------------------------------------------------------------------

tool_nvim() {
  local current=""
  has nvim && current="$(nvim --version | sed -n '1s/^NVIM v\([0-9.]*\).*/\1/p')"
  need nvim "$current" "$NVIM_MIN" || { ok "nvim $current"; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  fetch neovim/neovim "nvim-linux-$NVIM_ARCH.tar.gz" "$tmp/nvim.tar.gz"
  rm -rf "$OPT/nvim"
  mkdir -p "$OPT/nvim"
  tar -xzf "$tmp/nvim.tar.gz" -C "$OPT/nvim" --strip-components=1
  ln -sfn "$OPT/nvim/bin/nvim" "$BIN/nvim"
  rm -rf "$tmp"
  ok "nvim $FETCHED_TAG"
}

tool_tree_sitter() {
  local current=""
  has tree-sitter && current="$(tree-sitter --version | sed -n 's/^tree-sitter \([0-9.]*\).*/\1/p')"
  need tree-sitter "$current" "$TREE_SITTER_MIN" || { ok "tree-sitter $current"; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  fetch tree-sitter/tree-sitter "tree-sitter-linux-$TS_ARCH.gz" "$tmp/ts.gz"
  gzip -dc "$tmp/ts.gz" >"$BIN/tree-sitter"
  chmod +x "$BIN/tree-sitter"
  rm -rf "$tmp"
  ok "tree-sitter $FETCHED_TAG"
}

tool_lua_language_server() {
  need lua-language-server || { ok "lua-language-server"; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  fetch LuaLS/lua-language-server "lua-language-server-@VER@-linux-$LUA_ARCH.tar.gz" "$tmp/lls.tar.gz"
  rm -rf "$OPT/lua-language-server"
  mkdir -p "$OPT/lua-language-server"
  tar -xzf "$tmp/lls.tar.gz" -C "$OPT/lua-language-server"
  # The server finds its files relative to its own path: run it through a wrapper.
  printf '#!/bin/sh\nexec "%s/lua-language-server/bin/lua-language-server" "$@"\n' "$OPT" >"$BIN/lua-language-server"
  chmod +x "$BIN/lua-language-server"
  rm -rf "$tmp"
  ok "lua-language-server $FETCHED_TAG"
}

tool_stylua() {
  need stylua || { ok "stylua"; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  fetch JohnnyMorganz/StyLua "stylua-linux-$STYLUA_ARCH.zip" "$tmp/stylua.zip"
  unzip -oq "$tmp/stylua.zip" -d "$tmp"
  install -m 0755 "$tmp/stylua" "$BIN/stylua"
  rm -rf "$tmp"
  ok "stylua $FETCHED_TAG"
}

tool_golangci_lint() {
  need golangci-lint || { ok "golangci-lint"; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  fetch golangci/golangci-lint "golangci-lint-@VER@-linux-$GOLANGCI_ARCH.tar.gz" "$tmp/gl.tar.gz"
  tar -xzf "$tmp/gl.tar.gz" -C "$tmp"
  install -m 0755 "$tmp"/golangci-lint-*/golangci-lint "$BIN/golangci-lint"
  rm -rf "$tmp"
  ok "golangci-lint $FETCHED_TAG"
}

tool_texlab() {
  need texlab || { ok "texlab"; return 0; }
  local tmp
  tmp="$(mktemp -d)"
  fetch latex-lsp/texlab "texlab-$TEXLAB_ARCH-linux.tar.gz" "$tmp/texlab.tar.gz"
  tar -xzf "$tmp/texlab.tar.gz" -C "$tmp"
  install -m 0755 "$tmp/texlab" "$BIN/texlab"
  rm -rf "$tmp"
  ok "texlab $FETCHED_TAG"
}

tool_kubectl() {
  need kubectl || { ok "kubectl"; return 0; }
  local tmp version
  tmp="$(mktemp -d)"
  version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  info "Downloading kubectl $version"
  curl -fsSL -o "$tmp/kubectl" "https://dl.k8s.io/release/$version/bin/linux/$K8S_ARCH/kubectl"
  verify "$tmp/kubectl" "$(curl -fsSL "https://dl.k8s.io/release/$version/bin/linux/$K8S_ARCH/kubectl.sha256")" kubectl
  install -m 0755 "$tmp/kubectl" "$BIN/kubectl"
  rm -rf "$tmp"
  ok "kubectl $version"
}

# Debian and Ubuntu install fd as fdfind (the name fd is taken by another package).
tool_fd() {
  if has fd || ! has fdfind; then ok "fd"; return 0; fi
  ln -sfn "$(command -v fdfind)" "$BIN/fd"
  ok "fd -> fdfind"
}

tool_powerlevel10k() {
  local dir="$HOME/.local/share/powerlevel10k"
  if [ -d "$dir" ]; then
    [ -z "${TOOLS_UPDATE:-}" ] || git -C "$dir" pull -q --ff-only
    ok "powerlevel10k"
    return 0
  fi
  info "Cloning powerlevel10k"
  git clone -q --depth 1 https://github.com/romkatv/powerlevel10k.git "$dir"
  ok "powerlevel10k"
}

# --- run ---------------------------------------------------------------------

TOOLS=(nvim tree_sitter lua_language_server stylua golangci_lint texlab kubectl fd powerlevel10k)

# Child run: one tool (a failing tool must not stop the others, and `set -e` is
# ignored inside functions called from `||`, so each tool gets its own process).
if [ -n "${TOOLS_ONLY:-}" ]; then
  "tool_$TOOLS_ONLY"
  exit 0
fi

has jq || die "jq is missing: run ./install.sh packages"
has curl || die "curl is missing: run ./install.sh packages"

failed=()
for tool in "${TOOLS[@]}"; do
  TOOLS_ONLY="$tool" bash "$0" || failed+=("$tool")
done
if [ ${#failed[@]} -gt 0 ]; then
  die "tools failed: ${failed[*]}"
fi
ok "tools in $BIN"
