#!/usr/bin/env bash
# Step: LaTeX. TeX Live when latexmk is missing (macOS: MacTeX, Linux: Homebrew's
# texlive), then Skim's sync with Neovim (macOS). texlab and Skim come from the Brewfiles.
set -eo pipefail
. "$(dirname "$0")/lib.sh"
load_brew || die "Homebrew is missing: run ./install.sh packages"

if has latexmk || [ -x /Library/TeX/texbin/latexmk ]; then
  ok "TeX Live already installed"
elif [ "$OS" = macos ]; then
  info "Installing MacTeX (TeX Live, about 6 GB; asks for your password)"
  brew install --cask mactex-no-gui
else
  info "Installing TeX Live (Homebrew)"
  brew install texlive
fi

if [ "$OS" = macos ]; then
  has nvim || die "Neovim is missing: run ./install.sh packages"
  skim=net.sourceforge.skim-app.skim
  # Cmd+Shift+click in the PDF opens that line in the running Neovim (VimTeX).
  defaults write "$skim" SKTeXEditorPreset -string "Custom"
  defaults write "$skim" SKTeXEditorCommand -string "$(command -v nvim)"
  defaults write "$skim" SKTeXEditorArguments -string "--headless -c \"VimtexInverseSearch %line '%file'\""
  # Reload the PDF after every build without asking.
  defaults write "$skim" SKAutoCheckFileUpdate -bool true
  defaults write "$skim" SKAutoReloadFileUpdate -bool true
  ok "Skim: sync with Neovim, auto reload"
elif ! has zathura; then
  warn "no SyncTeX PDF viewer: install zathura and zathura-pdf-mupdf from your distro"
fi
