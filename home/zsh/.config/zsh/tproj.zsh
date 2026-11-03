# tproj [-a "agent ..."] [project-directory] [session-name]
#
# Agents (1-3, top to bottom in the right column): claude, codex, agy.
# Default: claude (or $TPROJ_AGENTS if set).
#   tproj                          -> one claude pane
#   tproj -a "claude claude agy" ~/work/app

tproj() {
  emulate -L zsh

  local agents_arg="${TPROJ_AGENTS:-claude}" agents_given=0
  local -a args=()
  while (( $# )); do
    case "$1" in
      -a|--agents)
        if (( $# < 2 )); then
          print -u2 -- "tproj: $1 needs a value, e.g. -a \"claude codex\""
          return 2
        fi
        agents_arg="$2" agents_given=1
        shift 2
        ;;
      --agents=*) agents_arg="${1#*=}" agents_given=1; shift ;;
      -h|--help)
        print -r -- 'Usage: tproj [-a "agent ..."] [project-directory] [session-name]'
        print -r -- '  -a, --agents   1-3 of: claude, codex, agy (default: claude)'
        return 0
        ;;
      --) shift; args+=("$@"); break ;;
      -?*) print -u2 -- "tproj: unknown option: $1"; return 2 ;;
      *) args+=("$1"); shift ;;
    esac
  done
  set -- "${args[@]}"

  # Accept spaces or commas: "claude claude agy" or "claude,codex".
  local -a agents=(${=agents_arg//,/ })
  if (( ${#agents} < 1 || ${#agents} > 3 )); then
    print -u2 -- "tproj: pick 1-3 agents (got ${#agents}: ${agents[*]})"
    return 2
  fi

  local -A agent_role=(claude claude codex codex agy google google google gemini google)
  local -A agent_title=(claude "CLAUDE / plan" codex "CODEX / write" google "AGY / research")
  local agent
  for agent in "${agents[@]}"; do
    if [[ -z "${agent_role[$agent]-}" ]]; then
      print -u2 -- "tproj: unknown agent '$agent' (use claude, codex or agy)"
      return 2
    fi
  done

  if [[ -n "${TMUX:-}" ]]; then
    print -r -- "Already inside tmux. Use Ctrl+B, then s to change sessions."
    return 1
  fi

  if (( ! $+commands[tmux] )); then
    print -u2 -- "tmux is not installed"
    return 1
  fi

  zmodload zsh/parameter || return 1

  local requested="${1:-$PWD}"
  local prefix="${requested%%/*}"
  if [[ "$requested" != /* && -n "${nameddirs[$prefix]-}" ]]; then
    if [[ "$requested" == "$prefix" ]]; then
      requested="${nameddirs[$prefix]}"
    else
      requested="${nameddirs[$prefix]}/${requested#*/}"
    fi
  fi

  local root
  root="$(cd -- "$requested" 2>/dev/null && pwd -P)" || {
    print -u2 -- "Project not found: $requested"
    return 1
  }

  local name="${2:-${root:t}}"
  if [[ -z "$name" || "$name" == *:* ]]; then
    print -u2 -- "Invalid tmux session name: $name"
    return 1
  fi

  local target="=$name"
  local launcher="$HOME/.local/bin/tproj-pane"

  if command tmux has-session -t "$target" 2>/dev/null; then
    local saved_root
    saved_root="$(command tmux show-option -qv -t "${target}:" @tproj_root)"
    if [[ -n "$saved_root" && "$saved_root" != "$root" ]]; then
      print -u2 -- "Session '$name' belongs to: $saved_root"
      print -u2 -- "Supply another session name: tproj '$root' other-name"
      return 1
    fi
    if (( agents_given )); then
      print -u2 -- "tproj: session '$name' already exists; ignoring --agents"
    fi
    command tmux attach-session -t "$target"
    return $?
  fi

  if [[ ! -x "$launcher" ]]; then
    print -u2 -- "Missing executable: $launcher"
    print -u2 -- "Run 'make link' from your dotfiles repo."
    return 1
  fi

  # Detached tmux sessions otherwise begin around 80x24, which can make
  # the right-hand agent panes too small even before Ghostty attaches.
  local -a size_args=()
  if (( COLUMNS >= 100 && LINES >= 26 )); then
    size_args=(-x "$COLUMNS" -y "$LINES")
  fi

  command tmux new-session -d "${size_args[@]}" \
    -s "$name" -n dev -c "$root" "$launcher editor" || return 1

  command tmux set-option -t "${target}:" @tproj_root "$root"

  local editor left_bottom
  editor="$(command tmux display-message -p -t "${target}:dev" '#{pane_id}')"

  # Split off the RIGHT column first: 25% of total window width.
  local -a agent_panes=()
  local role="${agent_role[${agents[1]}]}"
  agent_panes+=("$(command tmux split-window -h -l 25% -d -P -F '#{pane_id}' \
    -t "$editor" -c "$root" "$launcher $role")") || return 1

  # Bottom LEFT shell: 20% of the left column's height.
  left_bottom="$(command tmux split-window -v -l 20% -d -P -F '#{pane_id}' \
    -t "$editor" -c "$root" "$launcher shell")" || return 1

  # Stack remaining agents under the first, splitting the last pane so
  # every agent ends up with an equal share of the column height.
  local -i i n=${#agents} pct
  for (( i = 2; i <= n; i++ )); do
    role="${agent_role[${agents[i]}]}"
    pct=$(( (100 * (n - i + 1) + (n - i + 2) / 2) / (n - i + 2) ))
    agent_panes+=("$(command tmux split-window -v -l "${pct}%" -d -P -F '#{pane_id}' \
      -t "${agent_panes[-1]}" -c "$root" "$launcher $role")") || return 1
  done

  command tmux select-pane -t "$editor" -T "NVIM"
  command tmux select-pane -t "$left_bottom" -T "SHELL"

  # Number duplicate agents: "CLAUDE #1 / plan", "CLAUDE #2 / plan".
  local -A role_total=() role_seen=()
  for agent in "${agents[@]}"; do
    role="${agent_role[$agent]}"
    (( role_total[$role]++ ))
  done
  local title
  for (( i = 1; i <= n; i++ )); do
    role="${agent_role[${agents[i]}]}"
    title="${agent_title[$role]}"
    if (( role_total[$role] > 1 )); then
      (( role_seen[$role]++ ))
      title="${title/ \// #${role_seen[$role]} /}"
    fi
    command tmux select-pane -t "${agent_panes[i]}" -T "$title"
  done

  command tmux select-pane -t "$editor"
  command tmux select-window -t "${target}:dev"
  command tmux attach-session -t "$target"
}
