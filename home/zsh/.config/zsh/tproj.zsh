# tproj [project-directory] [session-name]
# One tmux session per project with shell, code (nvim), claude and codex windows.

tproj() {
  emulate -L zsh

  if [[ -n "${TMUX:-}" ]]; then
    print -r -- "Already inside tmux. Use Ctrl+B, then s."
    return 1
  fi

  # Resolve Zsh named directories.
  zmodload zsh/parameter || return 1

  local requested="${1:-$PWD}"
  local prefix="${requested%%/*}"

  if [[ "$requested" != /* &&
        -n "${nameddirs[$prefix]-}" ]]; then
    if [[ "$requested" == "$prefix" ]]; then
      requested="${nameddirs[$prefix]}"
    else
      requested="${nameddirs[$prefix]}/${requested#*/}"
    fi
  fi

  local root
  root="$(cd "$requested" 2>/dev/null && pwd -P)" || {
    print -u2 -- "Project not found: $requested"
    return 1
  }

  local name="${2:-${root:t}}"
  local created=0

  if [[ -z "$name" || "$name" == *:* ]]; then
    print -u2 -- "Invalid tmux session name: $name"
    return 1
  fi

  # Create a new session only if missing.
  if ! command tmux has-session -t "=$name" 2>/dev/null; then

    command tmux new-session -d \
      -s "$name" \
      -n shell \
      -c "$root" || return 1

    created=1

    # Remember the project directory.
    command tmux set-option -t "=$name" \
      @tproj_root "$root"

  else
    # Guard against reusing a session belonging
    # to another project with the same folder name.
    local saved_root
    saved_root="$(command tmux show-option -qv \
      -t "=$name" @tproj_root)"

    if [[ -n "$saved_root" && "$saved_root" != "$root" ]]; then
      print -u2 -- "Session '$name' belongs to: $saved_root"
      print -u2 -- "Supply a different session name."
      return 1
    fi
  fi

  # CODE — Neovim
  if ! command tmux list-windows -t "=$name" \
      -F '#{window_name}' | grep -Fxq code; then

    command tmux new-window -d \
      -t "=$name:" \
      -n code \
      -c "$root" \
      "/bin/zsh -lic 'nvim; exec /bin/zsh -l'" \
      || return 1
  fi

  # CLAUDE — Claude Code
  if ! command tmux list-windows -t "=$name" \
      -F '#{window_name}' | grep -Fxq claude; then

    command tmux new-window -d \
      -t "=$name:" \
      -n claude \
      -c "$root" \
      "/bin/zsh -lic 'claude; exec /bin/zsh -l'" \
      || return 1
  fi

  # CODEX — Codex CLI
  if ! command tmux list-windows -t "=$name" \
      -F '#{window_name}' | grep -Fxq codex; then

    command tmux new-window -d \
      -t "=$name:" \
      -n codex \
      -c "$root" \
      "/bin/zsh -lic 'codex; exec /bin/zsh -l'" \
      || return 1
  fi

  # Start newly created sessions in Neovim.
  if (( created )); then
    command tmux select-window -t "=$name:code"
  fi

  # Attach to project session.
  command tmux attach-session -t "=$name"
}
