# ~/.zshrc — interactive shells (macOS + Linux).
# Login environment (PATH, Homebrew, toolchain homes) lives in ~/.zprofile.
# Feature modules live in ~/.config/zsh/*.zsh. Machine-only lines: ~/.zshrc.local.

# Fastfetch once per standalone terminal window (not inside tmux).
# Must run before the Powerlevel10k instant prompt.
if [[ -o interactive && -z ${TMUX:-} && -z ${_FASTFETCH_SHOWN:-} &&
      ( ${TERM_PROGRAM:l} == ghostty || ${TERM:-} == xterm-ghostty ) ]] && (( $+commands[fastfetch] )); then
  fastfetch
  typeset -g _FASTFETCH_SHOWN=1
fi

# Powerlevel10k instant prompt. Keep near the top; nothing below may print.
if [[ -r ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload -Uz compinit
compinit

for module in ~/.config/zsh/*.zsh(N); do
  source "$module"
done
unset module

[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

# Powerlevel10k theme: Homebrew install first, legacy ~/powerlevel10k clone second.
for p10k_theme in \
    ${HOMEBREW_PREFIX:-/nonexistent}/share/powerlevel10k/powerlevel10k.zsh-theme \
    ~/powerlevel10k/powerlevel10k.zsh-theme; do
  if [[ -r $p10k_theme ]]; then
    source "$p10k_theme"
    [[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh
    break
  fi
done
unset p10k_theme
