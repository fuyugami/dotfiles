# dotfiles

My development environment for **macOS and Linux** (Ubuntu Server 26.10 and other Debian-family
systems first, 26.04 LTS and 24.04 work too; Fedora as well): terminal, editor, languages, containers and AI agents, set up by
one idempotent installer.

| Area | Tools |
| --- | --- |
| Terminal | tmux · zsh + Powerlevel10k · fzf · zoxide; Ghostty (optional) |
| Editor | Neovim 0.12 (lazy.nvim, native LSP, tree-sitter) |
| Languages | Go · Node (nvm) + TypeScript · Python (Miniforge conda/mamba, uv) |
| Writing | LaTeX: TeX Live (MacTeX), VimTeX + latexmk, texlab, Skim (macOS) / Zathura (Linux) |
| Containers | Docker via Colima (macOS) or Docker Engine (Linux) |
| AI agents | Claude Code · Codex, with desktop notifications through Ghostty (macOS) |

## Install

**macOS**

```sh
xcode-select --install          # git, make, compilers (skip if installed)
git clone <repo-url> ~/dotfiles && cd ~/dotfiles
make setup                      # dotfiles + core tools; may ask for sudo and your git name/email
make install                    # optional: Go, TeX Live, Docker, agent CLIs (or pick: make latex)
make doctor                     # verify
```

**Linux** (Debian/Ubuntu or Fedora)

```sh
sudo apt install -y git curl make   # Fedora: sudo dnf install -y git curl make
git clone <repo-url> ~/dotfiles && cd ~/dotfiles
make setup
make install                    # optional, or pick single steps
make doctor
```

`make <target>` is a thin wrapper: `./install.sh <target>` does the same and works on a
machine without `make`.

Then open a new terminal and log in to the agents once (`claude`, `codex`). On Linux, also
log out and back in (Docker group). Ghostty is optional (`make ghostty` installs the macOS app; on a Linux desktop install it from ghostty.org). A server
needs no terminal app: connect from Ghostty over SSH and its terminfo is copied over automatically.

Steps come in two groups. **`setup`** (`make setup`) is what the dotfiles need: the configs
linked, plus the tools the shell and Neovim config rely on. **`install`** (`make install`)
re-links and adds the optional, heavier installs; it does not run setup, and warns when setup
is missing. `./install.sh` with no arguments runs both. Each step only does what is missing,
so re-running is safe and repairs a machine. Run single steps with `./install.sh node go` or
`make node go`.

| Step | Does |
| --- | --- |
| **setup** | |
| `packages` | macOS: Homebrew and the Brewfile. Linux: apt (Debian, Ubuntu) or dnf (Fedora) packages |
| `link` | Symlinks the configs in `home/` into `$HOME` |
| `git` | Asks for your name/email, stores them in `~/.config/git/config.local` (not in the repo) |
| `shell` | Makes zsh the login shell |
| `tmux` | tmux plugins: resurrect + continuum, so sessions survive a reboot |
| `node` | nvm, Node 24, global npm packages |
| `python` | uv, Miniforge (conda/mamba), the `dev` conda env |
| `tools` | Linux: what apt/dnf lack or ship too old (Neovim 0.12, tree-sitter-cli, lua-language-server, stylua, golangci-lint, kubectl) from official releases |
| **install** | |
| `link` | Re-links, so configs added since setup are in place |
| `go` | Official Go in `/usr/local/go`, Go tools |
| `latex` | TeX Live if missing (MacTeX on macOS), Skim set up to sync with Neovim |
| `docker` | macOS: Colima VM started at login; Linux: Docker Engine |
| `agents` | Claude Code and Codex CLIs, a starting Codex config |
| `ghostty` | optional: the Ghostty app (macOS cask; Linux desktops install it themselves). Its config is linked everywhere |

## How it works

- **Configs are symlinks.** Files in `home/<tool>/` mirror your home directory and are linked
  into place with GNU Stow, so `~/.zshrc` points to `~/dotfiles/home/zsh/.zshrc`. Edit configs
  at their usual paths; you are editing this repo. Existing files are moved to
  `~/.dotfiles-backup/` before linking.
- **Same setup on both systems.** Language toolchains come from their official installers
  (Go, nvm, Miniforge, uv, Claude Code); other CLI tools from Homebrew on macOS and from
  apt/dnf on Linux, with official release binaries where the distro is too old (Neovim,
  tree-sitter). OS differences are handled inside the configs.
- **Workspaces survive a reboot.** tmux saves every session, window, pane and directory
  every 10 minutes. After a reboot, run `tmux` once: it restores them and reruns Neovim,
  `claude --continue` and `codex resume --last` in their panes. Attach other tabs with
  `tmux attach` (it picks a session no tab shows yet) or switch with `Ctrl+B s`.
- **Private settings stay local.** Your git identity and anything in `~/.zshrc.local` /
  `~/.zprofile.local` are untracked.
- **Agent notifications.** Claude Code and Codex send desktop notifications through Ghostty,
  also from tmux windows in the background: Claude when it needs your permission or input,
  Codex when a turn ends or it needs approval while its pane isn't focused. Clicking one brings that Ghostty tab
  to the front; `Ctrl+B w` then picks the tmux window.

```
home/        configs, one folder per tool (zsh, git, tmux, ghostty, nvim, conda, claude, bin)
packages/    what gets installed: Brewfile (macOS), apt/dnf lists (Linux), npm, Go, conda
setup/       one script per install step, plus templates copied once (Codex config)
```

## Usage

### Everyday commands

`make` lists everything.

| Command | Does |
| --- | --- |
| `make doctor` | Check that configs are linked and tools are installed |
| `make update` | Update everything: Homebrew or apt/dnf, release-binary tools, npm globals, Go and its tools, uv, conda envs, Neovim plugins |
| `make <step>` | Run one install step again, e.g. after editing a package list |
| `make check` | macOS: show Brewfile entries that aren't installed yet |
| `make brew-cleanup` | macOS: show installed Homebrew packages that aren't in the Brewfile |
| `make tmux-reload` | Reload the tmux config |
| `make lint` | Check scripts and configs for syntax errors |
| `make unlink` | Remove all config symlinks |

### Shell

| Command / keys | Does |
| --- | --- |
| `tproj [-a "agents"] [dir] [name]` | Open a tmux session for a project: Neovim, a shell, and 1–3 agent panes on the right (`claude`, `codex`, `agy`; default `claude`), e.g. `tproj -a "claude claude agy"` |
| `z <part>` | Jump to a directory you use often |
| `~dev`, `~work`, `~docs`, `~dot` | Jump to named directories |
| `Ctrl+R` · `Ctrl+T` · `Alt+C` | fzf: search history · insert a file · cd into a directory |
| `Ctrl+X` `Ctrl+E` | Edit the current command in Neovim |
| `gst` `gaa` `gco` `gcb` `gl` `gp` `glog` | git shortcuts |

### tmux

| Keys | Does |
| --- | --- |
| `Ctrl+h/j/k/l` | Move between tmux panes and Neovim splits |
| `Ctrl+B` `c` | New window in the current directory |
| `Ctrl+B` `w` / `s` | Pick a window / session |
| `Cmd+K` or `Ctrl+B` `Ctrl+L` | Clear the screen (plain `Ctrl+L` moves to the right pane) |
| `Ctrl+B` `[` → `v` → `y` | Copy mode, select, copy to the system clipboard |
| `Ctrl+B` `r` | Reload the config |
| `Ctrl+B` `Ctrl+S` / `Ctrl+R` | Save / restore all sessions now (saving also happens every 10 min) |
| `Ctrl+B` `d` | Detach: back to the shell, tmux keeps running |

### Neovim

Leader is `Space`; press it and wait to see all mappings. Highlights: `Space ff` files,
`Space fg` grep, `Space e` file explorer, `gd` definition, `Space ca` code action,
`Space cf` format, `Space gs` git status, `Space mp` render Markdown.
Full list: [Neovim guide](home/nvim/.config/nvim/README.md).

## Customize

| To change | Edit | Guide |
| --- | --- | --- |
| CLI tools and apps | `packages/Brewfile` (macOS), `apt.txt` / `dnf.txt` (Linux) | [packages](packages/README.md) |
| npm / Go tools, Python envs | `packages/npm.txt`, `go.txt`, `conda/*.yml` | [packages](packages/README.md) |
| Shell aliases, PATH, prompt | `home/zsh/…`, `~/.zshrc.local` | [home → zsh](home/README.md#zsh) |
| git defaults and identity | `home/git/…`, `~/.config/git/config.local` | [home → git](home/README.md#git) |
| tmux keys and colors | `home/tmux/.config/tmux/tmux.conf` | [home → tmux](home/README.md#tmux) |
| Terminal font, theme | `home/ghostty/.config/ghostty/config.ghostty` | [home → Ghostty](home/README.md#ghostty) |
| Neovim plugins, languages | `home/nvim/.config/nvim/lua/…` | [Neovim](home/nvim/.config/nvim/README.md#customize) |
| Claude Code / Codex settings | `home/claude/…`, `~/.codex/config.toml` | [home → Claude](home/README.md#claude-code) |
| Install steps, Node version, Docker VM size | `setup/*.sh` | [setup](setup/README.md) |
| macOS / Linux differences, Colima | `setup/`, `packages/Brewfile`, `apt.txt` | [setup → macOS and Linux](setup/README.md#macos-and-linux) |

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `make doctor` says a file is "not linked" | An app replaced the symlink with a copy. Move its changes into the repo file, delete the copy, run `make link`. |
| No agent notifications | Allow Ghostty in System Settings → Notifications; run `make tmux-reload`; restart the agent. |
| `Ctrl+h/j/k/l` doesn't reach Neovim | Restart Neovim. |
| Linux: `docker: permission denied` | Log out and back in after `make docker`. |
| Sessions not restored after a reboot | Start tmux with `tmux`, not `tmux attach`. Check `~/.local/share/tmux/resurrect/last` exists; restore by hand with `Ctrl+B Ctrl+R`. Auto-restore is skipped when another tmux server is already running. |
| Need an old file back | Look in `~/.dotfiles-backup/`. |

To remove everything: `make unlink`, then restore what you need from `~/.dotfiles-backup/`.
