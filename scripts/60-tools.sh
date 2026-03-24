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

setup_noctalia() {
  if ! command -v qs >/dev/null 2>&1; then
    warn "Quickshell (qs) not found (should be installed via noctalia-qs AUR package). Skipping setup."
    return 0
  fi

  log "Running Noctalia initial setup"

  # Noctalia is started directly via exec-once in hyprland.conf
  # Disable the systemd user service to avoid race conditions
  systemctl --user disable noctalia-shell 2>/dev/null || true

  # Create hypr/noctalia directory for config includes
  mkdir -p "$HOME/.config/hypr/noctalia"
  for f in colors.conf layout.conf outputs.conf; do
    [[ -f "$HOME/.config/hypr/noctalia/$f" ]] || touch "$HOME/.config/hypr/noctalia/$f"
  done
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
setup_noctalia
set_gnome_dark
