#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

# Wi-Fi: iwd is what iwgtk (tray) and iwctl talk to. When NetworkManager is
# installed (CachyOS default, also present on some Arch installs) it must not
# run wpa_supplicant on the same card, so make iwd its Wi-Fi backend and let
# NetworkManager keep doing IP configuration, Ethernet and VPNs.
setup_wifi() {
  if ! pacman -Q networkmanager >/dev/null 2>&1; then
    enable_service_now iwd.service
    return 0
  fi

  local conf=/etc/NetworkManager/conf.d/wifi_backend.conf
  if grep -qs '^wifi.backend=iwd' "$conf"; then
    log "NetworkManager already uses the iwd backend"
    enable_service_now iwd.service
    return 0
  fi

  log "Switching NetworkManager Wi-Fi backend to iwd"
  printf '[device]\nwifi.backend=iwd\n' | sudo tee "$conf" >/dev/null
  sudo systemctl disable --now wpa_supplicant.service 2>/dev/null || true
  enable_service_now iwd.service
  sudo systemctl restart NetworkManager.service || true
  warn "Wi-Fi networks saved by wpa_supplicant may need to be re-added"
}

setup_wifi

# Bluetooth
enable_service_now bluetooth.service

# Power profile daemon (D-Bus activated, but enable for predictability)
enable_service_now power-profiles-daemon.service

# Docker: enable only to avoid install hangs on some machines
enable_service docker.service
warn "Docker enabled. Start after reboot or manually: sudo systemctl start docker"

# Try to start docker but never hang the installer
start_service_timeout docker.service 10 || warn "Docker start timed out, skipping"
