# Everyday tasks for ~/dotfiles. Bare machine? Run ./install.sh first
# (make itself arrives with the Xcode Command Line Tools / build-essential).
# Compatible with GNU Make 3.81 (macOS default).

SHELL := /bin/bash
.DEFAULT_GOAL := help

STEPS := packages link git shell tmux node python go latex docker agents
HOME_PACKAGES := $(shell find home -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
CONDA := $(firstword $(wildcard $(HOME)/miniforge3/bin/mamba $(HOME)/miniforge3/bin/conda))
BREW := source setup/lib.sh && load_brew &&

.PHONY: help install doctor $(STEPS) check lint unlink tmux-reload brew-cleanup \
	update update-brew update-npm update-go update-uv update-conda update-nvim update-tmux

##@ Setup

install: ## Run every install step (same as ./install.sh)
	@./install.sh

$(STEPS):
	@./install.sh $@

doctor: ## Check links, tools and git identity
	@./install.sh doctor

##@ Update

update: update-brew update-npm update-go update-uv update-conda update-nvim update-tmux ## Update everything below

update-brew: ## brew update + upgrade
	@$(BREW) brew update && brew upgrade

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

check: ## Show Brewfile entries that are not installed
	@$(BREW) for f in packages/Brewfile $$([ "$$(uname -s)" = Darwin ] && echo packages/Brewfile.macos); do \
		echo "==> $$f"; brew bundle check --no-upgrade --verbose --file="$$f" || true; done

brew-cleanup: ## List installed brew packages missing from the Brewfiles (dry run)
	@$(BREW) tmp=$$(mktemp) && cat packages/Brewfile $$([ "$$(uname -s)" = Darwin ] && echo packages/Brewfile.macos) > "$$tmp" && \
		brew bundle cleanup --file="$$tmp"; rm -f "$$tmp"; \
		echo "Add what you want to keep to a Brewfile; remove the rest with: brew uninstall <name>"

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
	@printf "\n\033[1mSingle steps\033[0m (see ./install.sh --help)\n  %s\n" "$(STEPS)"
