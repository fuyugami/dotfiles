# ~/.zprofile — login environment (macOS + Linux).
# Machine-only additions: ~/.zprofile.local (untracked).

# Homebrew: Apple Silicon, Intel macOS, then Linuxbrew.
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $brew_bin ]]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done
unset brew_bin

# Toolchain homes
export GOPATH="$HOME/go"
export NVM_DIR="$HOME/.nvm"

case $OSTYPE in
  darwin*)
    export PNPM_HOME="$HOME/Library/pnpm"
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    [[ -d $HOME/Library/Java/JavaVirtualMachines/openjdk-21.0.1/Contents/Home ]] &&
      export JAVA_HOME="$HOME/Library/Java/JavaVirtualMachines/openjdk-21.0.1/Contents/Home"
    ;;
  linux*)
    export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
    ;;
esac

# PATH: remove duplicates, prepend user tool dirs, drop the ones that don't exist.
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$PNPM_HOME/bin"
  "$GOPATH/bin"
  /usr/local/go/bin
  ${ANDROID_HOME:+$ANDROID_HOME/platform-tools}
  "$HOME/.antigravity/antigravity/bin"
  $path
)
path=($^path(N-/))
export PATH

[[ -r ~/.zprofile.local ]] && source ~/.zprofile.local
