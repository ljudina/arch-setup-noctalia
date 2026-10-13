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
    # .zshrc holds machine-local secrets and is gitignored; the repo only
    # ships .zshrc.template. Skip the template itself (handled below).
    [[ "$base" == ".zshrc.template" ]] && continue
    link_one "$item" "$dst_root/$base"
  done
}

# Materialize a local .zshrc from the tracked template on first install.
# The live .zshrc is gitignored so per-machine secrets never get committed.
if [[ -f "$DOT/home/.zshrc.template" && ! -e "$DOT/home/.zshrc" ]]; then
  log "Creating dotfiles/home/.zshrc from template"
  cp "$DOT/home/.zshrc.template" "$DOT/home/.zshrc"
fi

log "Applying dotfiles via symlinks"
sync_dir_entries "$DOT/home"   "$HOME"
sync_dir_entries "$DOT/config" "$HOME/.config"
mkdir -p "$HOME/Pictures"
[[ -d "$DOT/Pictures/wallpapers" ]] && link_one "$DOT/Pictures/wallpapers" "$HOME/Pictures/wallpapers"
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# xdg-desktop-portal 1.22+ has Requisite=graphical-session.target. A bare
# Hyprland session never activates that target, so the portal fails to start
# and GTK/libadwaita apps fall back to the light theme. Provide a session
# target (started from hyprland.lua) that binds graphical-session.target.
mkdir -p "$HOME/.config/systemd/user"
session_target="$HOME/.config/systemd/user/hyprland-session.target"
if [[ ! -f "$session_target" ]]; then
  log "Creating systemd hyprland-session.target"
  cat > "$session_target" <<'EOF'
[Unit]
Description=Hyprland session
Documentation=man:systemd.special(7)
BindsTo=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target
EOF
  systemctl --user daemon-reload 2>/dev/null || true
fi
if [[ -d "$HOME/.local/share/nvim-php-config" ]]; then
  link_one "$HOME/.local/share/nvim-php-config" "$HOME/.config/nvim"
else
  log "Skipping nvim link (repo not found yet): $HOME/.local/share/nvim-php-config"
fi
log "Dotfiles applied"
