# Everyday tasks for ~/dotfiles. Needs `make` (macOS: Xcode Command Line Tools;
# Linux: apt/dnf install make). Without it, ./install.sh <target> does the same.
# Compatible with GNU Make 3.81 (macOS default).

SHELL := /bin/bash
.DEFAULT_GOAL := help

SETUP_STEPS := packages link git shell tmux node python tools
INSTALL_STEPS := go latex docker agents ghostty
STEPS := $(SETUP_STEPS) $(INSTALL_STEPS)
HOME_PACKAGES := $(shell find home -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
CONDA := $(firstword $(wildcard $(HOME)/miniforge3/bin/mamba $(HOME)/miniforge3/bin/conda))
BREW := source setup/lib.sh && { load_brew || true; } &&
MACOS_ONLY := [ "$$(uname -s)" = Darwin ] || { echo "macOS only (Linux: apt/dnf, see make update-apt)"; exit 0; };

.PHONY: help setup install doctor $(STEPS) check lint unlink tmux-reload brew-cleanup \
	update update-brew update-apt update-tools update-npm update-go update-uv update-conda update-nvim update-tmux

##@ Setup

setup: ## Dotfiles + what shell/Neovim need (packages link git shell tmux node python tools)
	@./install.sh setup

install: ## link + go latex docker agents ghostty (run setup first)
	@./install.sh install

$(STEPS):
	@./install.sh $@

doctor: ## Check links, tools and git identity
	@./install.sh doctor

##@ Update

update: update-brew update-apt update-tools update-npm update-go update-uv update-conda update-nvim update-tmux ## Update everything below

update-brew: ## macOS: brew update + upgrade
	@$(MACOS_ONLY) $(BREW) brew update && brew upgrade

update-apt: ## Linux: upgrade apt/dnf packages
	@if command -v apt-get >/dev/null; then sudo apt-get update && sudo apt-get upgrade -y; \
	elif command -v dnf >/dev/null; then sudo dnf upgrade -y; else echo "no apt or dnf (macOS: make update-brew)"; fi

update-tools: ## Linux: reinstall release-binary tools (Neovim, tree-sitter, ...) at latest
	@TOOLS_UPDATE=1 ./install.sh tools

update-npm: ## Update global npm packages of the default Node
	@source setup/lib.sh && load_nvm && npm update -g

update-go: ## Upgrade Go (go.dev) and reinstall Go tools at @latest
	@GO_UPDATE=1 ./install.sh go

update-uv: ## uv self update
	@~/.local/bin/uv self update

update-conda: ## Sync conda envs with packages/conda/*.yml
	@test -n "$(CONDA)" || { echo "Miniforge missing: make python"; exit 1; }
	@for f in packages/conda/*.yml; do echo "==> $$f"; $(CONDA) env update -y -f "$$f" || exit 1; done

update-tmux: ## Update tmux plugins
	@for d in ~/.local/share/tmux/plugins/*/; do echo "==> $$(basename "$$d")"; git -C "$$d" pull -q --ff-only || exit 1; done

update-nvim: ## Update Neovim plugins (then commit lazy-lock.json)
	@nvim --headless "+Lazy! sync" +qa
	@git --no-pager diff --stat -- home/nvim/.config/nvim/lazy-lock.json

##@ Maintenance

check: ## macOS: show Brewfile entries that are not installed
	@$(MACOS_ONLY) $(BREW) brew bundle check --no-upgrade --verbose --file=packages/Brewfile || true

brew-cleanup: ## macOS: list installed brew packages missing from the Brewfile (dry run)
	@$(MACOS_ONLY) $(BREW) brew bundle cleanup --file=packages/Brewfile; \
		echo "Add what you want to keep to the Brewfile; remove the rest with: brew uninstall <name>"

lint: ## Syntax-check scripts, zsh and tmux configs (+ shellcheck if installed)
	@bash -n install.sh setup/*.sh && echo "bash ok"
	@zsh -n home/zsh/.zshrc home/zsh/.zprofile home/zsh/.config/zsh/*.zsh && echo "zsh ok"
	@sh -n home/bin/.local/bin/* && echo "bin ok"
	@DOTFILES_LINT=1 tmux -L dotfiles-lint -f home/tmux/.config/tmux/tmux.conf new-session -d && \
		tmux -L dotfiles-lint kill-server && echo "tmux ok"
	@if command -v shellcheck >/dev/null; then \
		shellcheck -x -e SC1090,SC1091 install.sh setup/*.sh home/bin/.local/bin/* && echo "shellcheck ok"; \
	else echo "shellcheck not installed (brew install shellcheck)"; fi

unlink: ## Remove all symlinks created by `make link`
	@$(BREW) stow --dir=home --target="$$HOME" --delete $(HOME_PACKAGES) && echo "unlinked: $(HOME_PACKAGES)"

tmux-reload: ## Reload tmux config in the running server
	@tmux source-file ~/.config/tmux/tmux.conf && echo "tmux reloaded"

help: ## Show this help
	@echo "Usage: make <target>"
	@awk 'BEGIN {FS = ":.*## "} \
		/^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} \
		/^[a-z-]+:.*## / {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\n\033[1mSingle steps\033[0m (see ./install.sh --help)\n  setup:   %s\n  install: %s\n" "$(SETUP_STEPS)" "$(INSTALL_STEPS)"
