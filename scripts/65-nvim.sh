#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NVIM_REPO="https://github.com/ljudina/php.nvim"
NVIM_DIR="$HOME/.local/share/nvim-php-config"

log() { printf "\n==> %s\n" "$*"; }

if [[ -d "$NVIM_DIR/.git" ]]; then
  log "Updating Neovim config repo"
  git -C "$NVIM_DIR" pull --ff-only
else
  log "Cloning Neovim config repo"
  mkdir -p "$(dirname "$NVIM_DIR")"
  git clone "$NVIM_REPO" "$NVIM_DIR"
fi

# Bootstrap/update the Neovim binary itself into /opt/nvim. The pacman 'neovim'
# package is intentionally not installed (removed from config/pacman.txt) in
# favor of this script-managed build, so a fresh machine depends on this step
# for the nvim binary. update_nvim.sh needs root and only re-downloads when a
# newer release exists, so it is safe to run on every install.
UPDATE_SCRIPT="$NVIM_DIR/update_nvim.sh"
if [[ -f "$UPDATE_SCRIPT" ]]; then
  log "Installing/updating Neovim binary into /opt/nvim"
  sudo bash "$UPDATE_SCRIPT" || log "Neovim binary update failed (continuing)"
else
  log "update_nvim.sh not found in config repo, skipping Neovim binary install"
fi
