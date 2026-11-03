# setup/ — install steps

`./install.sh [setup | install | step …]` (or `make <step>`) runs these scripts, grouped:

```
setup   (make setup)    packages → link → git → shell → tmux → node → python
install (make install)  link → go → latex → docker → agents
```

`install` never runs setup; it warns when setup looks missing (no stow, git
identity, nvm or Miniforge; Homebrew on macOS) and carries on. No arguments runs `setup` then `install`; a
step named twice (`link`) runs once.

`doctor` is a separate check. Each script works on macOS and Linux and is **idempotent**:
it checks first and only does what is missing.

A step that fails is reported (`[node] failed (exit 1)`) and the remaining steps still
run; the run ends with the list of failed steps to re-run. A step that needs another
one (e.g. stow from `packages`) stops with a message naming it.

| Script | Does | Settings you can change |
| --- | --- | --- |
| [`packages.sh`](packages.sh) | macOS: Xcode CLT check, Homebrew, `brew bundle --no-upgrade`. Linux: `apt-get` (Debian, Ubuntu) or `dnf` (Fedora) with `apt.txt` / `dnf.txt`; names the release lacks are skipped with a warning | lists in [`packages/`](../packages/README.md); `apt.txt` accepts `name>=version` |
| [`tools.sh`](tools.sh) | Linux: Neovim (≥ 0.12), tree-sitter-cli (≥ 0.26.1), lua-language-server, stylua, golangci-lint, lazygit, kubectl, texlab and Powerlevel10k from official releases when apt/dnf lack them or are too old; sha256-verified, into `~/.local/opt` and `~/.local/bin`. macOS: nothing to do | `NVIM_MIN`, `TREE_SITTER_MIN`; env `TOOLS_UPDATE=1`, `GITHUB_TOKEN` |
| [`link.sh`](link.sh) | Backs up conflicting files, then `stow` every package in `home/` | `FOLDED`, `PER_FILE` package lists |
| [`git.sh`](git.sh) | Creates `~/.config/git/config.local` (identity), retires `~/.gitconfig` | — |
| [`shell.sh`](shell.sh) | `chsh` to the system zsh | — |
| [`tmux.sh`](tmux.sh) | Clones TPM and every `@plugin` in `tmux.conf` into `~/.local/share/tmux/plugins` | the `@plugin` lines |
| [`node.sh`](node.sh) | nvm git checkout, Node default, `npm.txt` globals | `NVM_VERSION`, `NODE_VERSION` |
| [`python.sh`](python.sh) | uv installer, Miniforge, conda envs | install prefix `prefix=` |
| [`go.sh`](go.sh) | Go from go.dev into `/usr/local/go` (sha256-verified), `go.txt` tools | `GOROOT_DIR`; env `GO_UPDATE=1` |
| [`latex.sh`](latex.sh) | TeX Live if `latexmk` is missing (macOS: MacTeX cask, Linux: apt/dnf TeX Live packages), Skim's inverse search into Neovim and auto reload | Skim `defaults` keys |
| [`ghostty.sh`](ghostty.sh) | optional: `brew install --cask ghostty` on macOS; Linux: nothing (no apt/dnf package) | — |
| [`docker.sh`](docker.sh) | macOS: buildx/compose plugins, Colima VM, `brew services`; Linux: Docker Engine + `docker` group | Colima `--cpu/--memory/--disk` flags |
| [`agents.sh`](agents.sh) | Claude Code, Codex (Linux via npm), seeds `~/.codex/config.toml` | [`templates/codex/config.toml`](templates/codex/config.toml) |
| [`doctor.sh`](doctor.sh) | Checks every link, the expected tools, the conda envs (with their Python version), tmux plugins and git identity | `tools=` list |
| [`lib.sh`](lib.sh) | Shared helpers (sourced, not a step) | — |

## Common changes

- **Node version:** set `NODE_VERSION` in `node.sh`, run `make node`. Existing versions
  stay installed; globals are installed for the new default.
- **Colima size** (only used when the VM is first created): edit the `colima start` flags in
  `docker.sh`. For an existing VM: `colima stop && colima start --cpu 6 --memory 8`
  (disk can only grow: `--disk 100`).
- **Go install location:** `GOROOT_DIR` in `go.sh` and `/usr/local/go/bin` in
  `home/zsh/.zprofile` must match.
- **Skip a step on a machine:** run the others explicitly, e.g.
  `./install.sh packages link git shell node`.
- **Move a step between setup and install:** edit `SETUP_STEPS` / `INSTALL_STEPS` in
  [`install.sh`](../install.sh), the same lines in the [`Makefile`](../Makefile), and the
  `setup` / `install` help text there.
- **What `doctor` checks:** edit the `tools=` list in `doctor.sh`.

## macOS and Linux

The steps are the same on both; these are the differences.

| | macOS | Linux |
| --- | --- | --- |
| Base packages | Xcode Command Line Tools | `packages/apt.txt` / `dnf.txt` |
| CLI tools | Homebrew (`/opt/homebrew` or `/usr/local`), `packages/Brewfile` | `apt` (Debian, Ubuntu) / `dnf` (Fedora): `apt.txt`, `dnf.txt`; no Homebrew |
| Neovim, tree-sitter, lua-language-server, stylua, golangci-lint, lazygit, kubectl | Brewfile | `tools` step (official releases, `~/.local/bin`) |
| Docker | Colima VM + Docker CLI (below) | Docker Engine from get.docker.com, you're added to the `docker` group (log out/in once) |
| Codex CLI | `cask "codex"` in the Brewfile | `npm install -g @openai/codex` |
| LaTeX | MacTeX + Skim | apt/dnf TeX Live; PDF viewer: install `zathura` + `zathura-pdf-mupdf` from your distro |
| Ghostty | optional: `make ghostty` (cask) | desktop: install from ghostty.org; server: not needed, SSH in from Ghostty (`ssh-terminfo` copies the terminfo over). Config is linked on both |
| `PNPM_HOME` | `~/Library/pnpm` | `~/.local/share/pnpm` |

Both: Go lives in `/usr/local/go` (the go.dev macOS installer also adds `/etc/paths.d/go`;
keep both), the login shell is the system zsh, tmux copies via OSC 52 (works under
Wayland, X11 and SSH), and agent notifications go through Ghostty (macOS: allow Ghostty
in System Settings → Notifications; over SSH they still reach your local Ghostty).

The Linux path is less exercised than macOS. If a step fails, fix it in the matching
script (check the `$OS = linux` branches) and re-run only that step. For rootless Docker
or Podman, skip `make docker`; nothing else depends on it.

### Docker with Colima (macOS)

`make docker` creates a Colima VM (4 CPU, 6 GiB RAM, 60 GiB disk, Apple `vz` with Rosetta
for amd64 images) and starts it at login with `brew services`. Docker's `colima` context is
used automatically; buildx and compose are linked into `~/.docker/cli-plugins`.

| Task | Command |
| --- | --- |
| Status | `colima status`, `docker context ls` |
| Stop / start | `brew services stop colima` / `brew services start colima` |
| Resize | `colima stop && colima start --cpu 6 --memory 8 --disk 100` (disk only grows) |
| Settings file | `~/.colima/default/colima.yaml` (machine-local, not tracked) |
| Kubernetes | `colima start --kubernetes` |
| Reset everything | `colima delete && make docker` |

## Add a step

1. Create `setup/<name>.sh` from this template and `chmod +x` it:
   ```bash
   #!/usr/bin/env bash
   # Step: what it installs or configures, on which OS.
   set -eo pipefail
   . "$(dirname "$0")/lib.sh"

   if has rustup; then
     ok "rustup already installed"
   else
     info "Installing rustup"
     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
   fi
   ```
2. Add it to `SETUP_STEPS` or `INSTALL_STEPS` in `install.sh` and the `Makefile` (or leave
   it out of both and call it as `./install.sh <name>`).
3. If it adds a binary dir, add it to `PATH` in `home/zsh/.zprofile`.
4. Run `make lint` and the step twice to prove it is idempotent.

**Rules for steps:** check before installing; never edit shell rc files (installers get
`--no-modify-path` / `PROFILE=/dev/null` style flags; PATH lives in `.zprofile`); stay
compatible with macOS's bash 3.2 (no associative arrays, `mapfile`, `${var,,}`); prefer
official installers and verify checksums when the project publishes them.

## Helpers in `lib.sh`

| Helper | Purpose |
| --- | --- |
| `$DOTFILES`, `$OS` (`macos`/`linux`) | repo path and platform |
| `info` / `ok` / `warn` / `die` | colored output; `die` exits |
| `has <cmd>` | command exists on `PATH` |
| `load_brew` / `load_nvm` | put Homebrew / nvm into the current process |
| `read_list <file>` | print a package list without comments and blank lines |
| `backup <path>` | move a file to `~/.dotfiles-backup/<time>/`, keeping its path |
