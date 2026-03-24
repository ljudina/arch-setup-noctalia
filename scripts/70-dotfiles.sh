#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOT="$ROOT_DIR/dotfiles"

log() { printf "\n==> %s\n" "$*"; }

link_one() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"

  # Backup real file/dir that would block the link
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    local bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    log "Backing up $dst -> $bak"
    mv "$dst" "$bak"
  fi

  # Replace wrong symlink
  if [[ -L "$dst" ]]; then
    local cur
    cur="$(readlink "$dst")"
    if [[ "$cur" != "$src" ]]; then
      log "Updating symlink $dst -> $src"
      rm -f "$dst"
      ln -s "$src" "$dst"
    else
      log "Symlink OK: $dst"
    fi
    return 0
  fi

  log "Linking $dst -> $src"
  ln -s "$src" "$dst"
}

sync_dir_entries() {
  local src_root="$1" dst_root="$2"
  [[ -d "$src_root" ]] || return 0
  shopt -s dotglob nullglob
  for item in "$src_root"/*; do
    local base
    base="$(basename "$item")"
    link_one "$item" "$dst_root/$base"
  done
}

log "Applying dotfiles via symlinks"
sync_dir_entries "$DOT/home"   "$HOME"
sync_dir_entries "$DOT/config" "$HOME/.config"
mkdir -p "$HOME/Pictures"
[[ -d "$DOT/Pictures/wallpapers" ]] && link_one "$DOT/Pictures/wallpapers" "$HOME/Pictures/wallpapers"
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
mkdir -p "$HOME/.config/hypr/noctalia"
for f in colors.conf layout.conf outputs.conf; do
  [[ -f "$HOME/.config/hypr/noctalia/$f" ]] || touch "$HOME/.config/hypr/noctalia/$f"
done
if [[ -d "$HOME/.local/share/nvim-php-config" ]]; then
  link_one "$HOME/.local/share/nvim-php-config" "$HOME/.config/nvim"
else
  log "Skipping nvim link (repo not found yet): $HOME/.local/share/nvim-php-config"
fi
log "Dotfiles applied"
