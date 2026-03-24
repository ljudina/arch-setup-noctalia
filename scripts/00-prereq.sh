#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

need_cmd sudo

log "Refreshing pacman databases"
sudo pacman -Sy --noconfirm

# tools needed for later steps
log "Installing prerequisites (git, base-devel)"
sudo pacman -S --needed --noconfirm git base-devel curl

need_cmd git
need_cmd curl
need_cmd makepkg
