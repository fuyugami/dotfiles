#!/usr/bin/env bash
# Restore the last tmux-resurrect save, but only on the first tmux server start
# after a reboot. Killing every session (or the server) and starting tmux again
# in the same boot gives a clean start; Ctrl+B, then Ctrl+R still restores.
# Run once per server start from tmux.conf (replaces @continuum-restore 'on',
# which restores on *every* server start).
set -u

boot_time() {
  case "$(uname -s)" in
    Darwin) sysctl -n kern.boottime | sed 's/^{ sec = \([0-9]*\),.*/\1/' ;;
    *) awk '/^btime/ {print $2}' /proc/stat ;;
  esac
}

dir="$(tmux show-option -gqv @resurrect-dir)"
dir="${dir:-${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect}"
dir="${dir/#\~/$HOME}"
last="$dir/last"
marker="$dir/.restored-boot"

[ -e "$last" ] || exit 0
boot="$(boot_time)"
[ -n "$boot" ] || exit 0

# Already restored in this boot (e.g. the server was killed within the first
# save interval), or the save was written after boot: same boot, no restore.
[ "$(cat "$marker" 2>/dev/null)" != "$boot" ] || exit 0
[ "$(date -r "$last" +%s)" -lt "$boot" ] || exit 0

echo "$boot" >"$marker"
sleep 1 # let tpm finish loading resurrect
restore="$(tmux show-option -gqv @resurrect-restore-script-path)"
[ -x "$restore" ] && "$restore"
