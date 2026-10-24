#!/usr/bin/env bash
# Step: Docker.
#   macOS: Colima VM (4 CPU, 6 GiB, 60 GiB, vz + Rosetta) started at login by
#          brew services; Homebrew's buildx/compose registered as CLI plugins.
#   Linux: Docker Engine from get.docker.com; user added to the docker group.
set -eo pipefail
. "$(dirname "$0")/lib.sh"

if [ "$OS" = macos ]; then
  load_brew || die "Homebrew is missing: run ./install.sh packages"
  has colima || die "colima is missing: run ./install.sh packages"

  mkdir -p "$HOME/.docker/cli-plugins"
  for plugin in docker-buildx docker-compose; do
    ln -sfn "$(brew --prefix)/opt/$plugin/bin/$plugin" "$HOME/.docker/cli-plugins/$plugin"
  done

  if ! colima list 2>/dev/null | awk 'NR > 1 {print $1}' | grep -qx default; then
    info "Creating Colima VM"
    colima start --cpu 4 --memory 6 --disk 60 --vm-type vz --vz-rosetta
    colima stop
  fi
  if ! brew services list | awk '$1 == "colima" {print $2}' | grep -qx started; then
    brew services start colima
  fi
  ok "docker via colima ($(docker context show 2>/dev/null || echo 'context pending'))"
else
  if ! has docker; then
    info "Installing Docker Engine (get.docker.com)"
    curl -fsSL https://get.docker.com | sudo sh
  fi
  sudo systemctl enable --now docker >/dev/null 2>&1 || true
  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    warn "added $USER to the docker group: log out and back in"
  fi
  ok "docker engine"
fi
