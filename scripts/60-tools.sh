#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

install_atuin() {
  if command -v atuin >/dev/null 2>&1; then
    log "Atuin already installed"
    return 0
  fi
  log "Installing Atuin"
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
}

install_go_tools() {
  if ! command -v go >/dev/null 2>&1; then
    warn "Go not found, skipping Go tools"
    return 0
  fi

  log "Installing Go tools (templ, air)"
  go install github.com/a-h/templ/cmd/templ@latest
  go install github.com/air-verse/air@latest
}

remove_noctalia_v4() {
  # Noctalia v5 is a native rewrite packaged as "noctalia" in extra. The v4
  # Quickshell packages and their helpers are no longer used by this setup.
  # CachyOS still ships noctalia-shell 4.x in its [cachyos] repo, so this also
  # covers a CachyOS install that picked it up.
  # Removed one at a time so a package with other dependants does not block
  # the rest. -Rns also drops deps that become orphans (e.g. qt6-multimedia).
  local pkg
  for pkg in noctalia-shell noctalia-qs cliphist matugen wl-clip-persist; do
    pacman -Q "$pkg" >/dev/null 2>&1 || continue
    log "Removing Noctalia v4 leftover: $pkg"
    sudo pacman -Rns --noconfirm "$pkg" || warn "Could not remove $pkg (check dependants)"
  done
}

warn_uwsm_session() {
  # CachyOS's Hyprland profile installs uwsm and a greeter offering a
  # "Hyprland (UWSM)" session. hyprland.lua copes with it, but the plain
  # "Hyprland" session matches how this setup is tested.
  if pacman -Q uwsm >/dev/null 2>&1; then
    warn "uwsm is installed: pick the plain \"Hyprland\" session in the greeter, not \"Hyprland (UWSM)\""
  fi
}

setup_noctalia() {
  if ! command -v noctalia >/dev/null 2>&1; then
    warn "noctalia not found (should be installed from config/pacman.txt). Skipping setup."
    return 0
  fi
  # Noctalia is started from the Hyprland startup event in hyprland.lua and
  # reads every *.toml in ~/.config/noctalia (symlinked from dotfiles/config).
  log "Noctalia v5 present: $(noctalia --version 2>/dev/null | head -1)"
}

set_gnome_dark() {
  if ! command -v gsettings >/dev/null 2>&1; then
    warn "gsettings not available, skipping GNOME dark mode"
    return 0
  fi
  log "Setting GNOME color-scheme prefer-dark (if schema exists)"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
}

install_atuin
install_go_tools
remove_noctalia_v4
setup_noctalia
warn_uwsm_session
set_gnome_dark
