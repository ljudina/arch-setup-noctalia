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
