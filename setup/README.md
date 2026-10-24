# setup/ — install steps

`./install.sh [step …]` (or `make <step>`) runs these scripts. With no arguments it runs
every step in this order:

```
packages → link → git → shell → node → python → go → docker → agents
```

`doctor` is a separate check. Each script works on macOS and Linux and is **idempotent**:
it checks first and only does what is missing.

| Script | Does | Settings you can change |
| --- | --- | --- |
| [`packages.sh`](packages.sh) | Xcode CLT check (macOS) / apt or dnf base packages (Linux), Homebrew, `brew bundle --no-upgrade` | lists in [`packages/`](../packages/README.md) |
| [`link.sh`](link.sh) | Backs up conflicting files, then `stow` every package in `home/` | `FOLDED`, `PER_FILE` package lists |
| [`git.sh`](git.sh) | Creates `~/.config/git/config.local` (identity), retires `~/.gitconfig` | — |
| [`shell.sh`](shell.sh) | `chsh` to the system zsh | — |
| [`node.sh`](node.sh) | nvm git checkout, Node default, `npm.txt` globals | `NVM_VERSION`, `NODE_VERSION` |
| [`python.sh`](python.sh) | uv installer, Miniforge, conda envs | install prefix `prefix=` |
| [`go.sh`](go.sh) | Go from go.dev into `/usr/local/go` (sha256-verified), `go.txt` tools | `GOROOT_DIR`; env `GO_UPDATE=1` |
| [`docker.sh`](docker.sh) | macOS: buildx/compose plugins, Colima VM, `brew services`; Linux: Docker Engine + `docker` group | Colima `--cpu/--memory/--disk` flags |
| [`agents.sh`](agents.sh) | Claude Code, Codex (Linux via npm), seeds `~/.codex/config.toml` | [`templates/codex/config.toml`](templates/codex/config.toml) |
| [`doctor.sh`](doctor.sh) | Checks every link, the expected tools and git identity | `tools=` list |
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
- **Make a step part of the default run:** add it to `STEPS` in
  [`install.sh`](../install.sh) and the `STEPS` line in the [`Makefile`](../Makefile).
- **What `doctor` checks:** edit the `tools=` list in `doctor.sh`.

## macOS and Linux

The steps are the same on both; these are the differences.

| | macOS | Linux |
| --- | --- | --- |
| Base packages | Xcode Command Line Tools | `packages/apt.txt` / `dnf.txt` |
| Homebrew | `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel) | `/home/linuxbrew/.linuxbrew` |
| Docker | Colima VM + Docker CLI (below) | Docker Engine from get.docker.com, you're added to the `docker` group (log out/in once) |
| Codex CLI | `cask "codex"` in `Brewfile.macos` | `npm install -g @openai/codex` |
| Ghostty | `cask "ghostty"` | not installed: use your distro's package or [ghostty.org](https://ghostty.org); the config is linked already |
| `PNPM_HOME` | `~/Library/pnpm` | `~/.local/share/pnpm` |

Both: Go lives in `/usr/local/go` (the go.dev macOS installer also adds `/etc/paths.d/go`;
keep both), the login shell is the system zsh, tmux copies via OSC 52 (works under
Wayland, X11 and SSH), and agent notifications go through Ghostty (on macOS, allow Ghostty
in System Settings → Notifications).

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
2. Add it to `STEPS` in `install.sh` and the `Makefile` (or leave it out of the default
   run and call it as `./install.sh <name>`).
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
