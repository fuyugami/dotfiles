# packages/ — what gets installed

Declarative lists read by the install steps. Edit a list, re-run its step; steps only
install what is missing, so re-running is always safe.

| File | Installed by | Format |
| --- | --- | --- |
| [`Brewfile`](Brewfile) | `make packages` (macOS only) | Homebrew Bundle |
| [`apt.txt`](apt.txt) | `make packages` (Debian, Ubuntu) | one apt package per line |
| [`dnf.txt`](dnf.txt) | `make packages` (Fedora) | one dnf package per line |
| release binaries | `make tools` (Linux) | defined in [`setup/tools.sh`](../setup/tools.sh) |
| [`npm.txt`](npm.txt) | `make node` | one npm package per line |
| [`go.txt`](go.txt) | `make go` | one Go module path per line |
| [`conda/*.yml`](conda/) | `make python` | conda environment files |

In the `.txt` lists, blank lines and `# comments` are ignored.

## Where should a tool go?

1. **Language toolchain or a tool with its own official installer/updater** (Go, Node,
   Python, uv, Rust, Claude Code…) → its own step in [`setup/`](../setup/README.md), not
   Homebrew or apt. Same install on macOS and Linux, updates from the source.
2. **CLI tool you want on every machine** → the `Brewfile` (macOS) **and** `apt.txt` /
   `dnf.txt` (Linux), same tool in each. If apt's version is too old or missing (Ubuntu LTS
   often is), add it to the `tools` step instead of `apt.txt`.
3. **macOS app or macOS-only formula** → `Brewfile`. Ghostty is optional: `make ghostty`.
4. **Language-specific global tool you use everywhere** (language servers, package
   managers) → `npm.txt` or `go.txt`.
5. **Python packages** → a conda env file (or `uv` inside a project).
6. **Only for some projects** (codegen, mocks, framework CLIs, hook managers, databases) →
   that project's own manifest, pinned to its version: `go get -tool <module>` +
   `go tool <name>`, `devDependencies` + `npx`, or a `compose.yaml` service.

Only add things you'd want on a fresh machine; a Brewfile is a "install this everywhere" list.

## Brewfiles

```ruby
brew "ripgrep"                                     # formula
brew "libpq", link: true                           # keg-only formula, force link
brew "colima", restart_service: :changed           # restart its service on upgrade
cask "ghostty"                                     # macOS app
tap "owner/tap"                                    # third-party repository…
brew "owner/tap/tool", trusted: true               # …and a formula from it
brew "something-mac-only" if OS.mac?               # per-OS line in a shared Brewfile
```

| Task | Command |
| --- | --- |
| Install what's missing | `make packages` (never upgrades existing packages) |
| See what's missing | `make check` |
| Upgrade everything | `make update-brew` |
| Find installed packages not in any Brewfile | `make brew-cleanup` (dry run) |
| Add something you installed by hand | add the line, `make check` should then be clean |
| Remove a tool | delete the line, then `brew uninstall <name>` (or `--cask --zap` for apps) |

Shared groups: shell & terminal, editor tooling (Neovim, tree-sitter CLI, ripgrep, fd,
language servers incl. texlab, stylua), code quality (pre-commit, shellcheck, golangci-lint),
Kubernetes CLI and mkcert, docs & network (pandoc, wget, socat).

**macOS apps:** the `Brewfile` lists only apps the setup depends on (Codex, Skim; Ghostty is
optional: `make ghostty`) and
the Docker runtime (Colima + Docker CLI). Add `cask "<name>"` for apps you want on every
Mac; find names with `brew search <name>`, remove an app and its settings with
`brew uninstall --zap --cask <name>`.

## Linux base packages

`apt.txt` (Debian, Ubuntu) and `dnf.txt` (Fedora) hold the build tools and the CLI tools the
setup expects. A package name the release does not carry is skipped with a warning, not an
error (e.g. `fastfetch`, `texlab` on Ubuntu 24.04).

**Why not Homebrew on Linux?** Native packages are what Linux users expect and update with
the system. The gap is old LTS versions, so the `tools` step installs official release
binaries only where apt/dnf are missing or too old, checked against a version floor:

| Tool | Floor | Why |
| --- | --- | --- |
| Neovim | 0.12 | the config targets it (Ubuntu 26.10 has 0.12 in apt; 26.04 has 0.11, 24.04 has 0.9) |
| tree-sitter-cli | 0.26.1 | required by nvim-treesitter's `main` branch (apt: 26.10 has 0.26, 26.04 has 0.25) |
| lua-language-server, stylua, golangci-lint, kubectl | any | not in Ubuntu's repos |
| texlab | any | in Ubuntu 26.04's apt, otherwise downloaded |

`apt.txt` lists Neovim and tree-sitter-cli as `name>=version`, so apt installs them only where
its version meets the floor (Ubuntu 26.10) and `tools` downloads them everywhere else. Fedora's
and Ubuntu 26.10's repos are current, so `tools` only fetches lua-language-server, stylua,
golangci-lint and kubectl there. Downloads are verified
against the sha256 GitHub publishes for each asset. Update them with `make update-tools`.

- **Add a package:** one line in `apt.txt` (`name>=version` to require a minimum) and `dnf.txt` (names differ: `fd-find`,
  `ShellCheck`, `pandoc-cli` on Fedora) plus the `Brewfile` for macOS.
- **Another distro (e.g. Arch):** add `pacman.txt` and a `pacman` branch next to the
  `apt-get` / `dnf` ones in [`setup/packages.sh`](../setup/packages.sh).

## npm globals

Installed into the **default nvm Node** (`npm install -g`). Switching Node versions with
nvm gives you a separate set of globals; reinstall with
`nvm install 24 --reinstall-packages-from=current` or `make node`.

- Add/remove: edit [`npm.txt`](npm.txt), then `make node` (removal: `npm uninstall -g <pkg>`).
- Update all: `make update-npm`.
- Scoped packages work as-is (`@scope/name`).

## Go tools

Module paths without a version; `make go` runs `go install <module>@latest` for each tool
not yet in `~/go/bin`.

- The binary name is the last path element (`…/cmd/goimports` → `goimports`;
  a trailing `/v2` is skipped).
- The list always installs `@latest`. Tools a project needs at a fixed version go in that
  project: `go get -tool <module>@<version>`, run with `go tool <name>`.
- golangci-lint comes from the Brewfile (macOS) or its release binary (Linux): its authors recommend a binary install over
  `go install`.
- Update all: `make update-go` (also upgrades Go itself).
- Remove: delete the line and `rm ~/go/bin/<tool>`.

## Conda environments

Each `conda/<name>.yml` becomes an env called `name:`. `make python` creates missing envs
and leaves existing ones alone.

```yaml
name: dev
channels: [conda-forge]
dependencies:
  - python=3.13
  - numpy
  - pip
  - pip:            # pip-only packages
      - some-package
```

- Change an env: edit the yml, then `make update-conda` (updates every env file).
- New env: add `conda/<name>.yml`, `make python`; activate with `conda activate <name>`.
- The env that activates in every shell is set in [`home/conda/.condarc`](../home/conda/.condarc).
- Export what you installed by hand: `conda env export -n dev --from-history`.
