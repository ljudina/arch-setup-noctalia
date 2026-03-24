#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33mWARN:\033[0m %s\n" "$*"; }
err() { printf "\033[1;31mERROR:\033[0m %s\n" "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }
}

read_pkgs_file() {
  local file="$1"
  [[ -f "$file" ]] || { err "Missing packages file: $file"; exit 1; }

  # Ignore blank lines and comments
  grep -Ev '^\s*($|#)' "$file" | tr '\n' ' '
}

pac_install_file() {
  local file="$1"
  local pkgs
  pkgs="$(read_pkgs_file "$file")"
  [[ -n "$pkgs" ]] || return 0
  log "pacman install from $(basename "$file")"
  sudo pacman -S --needed --noconfirm $pkgs
}

aur_install_file() {
  local file="$1"
  local pkgs
  pkgs="$(read_pkgs_file "$file")"
  [[ -n "$pkgs" ]] || return 0
  log "AUR install from $(basename "$file")"
  paru -S --needed --noconfirm $pkgs
}

enable_service_now() {
  local svc="$1"
  log "Enable + start: $svc"
  sudo systemctl enable --now "$svc"
}

enable_service() {
  local svc="$1"
  log "Enable: $svc"
  sudo systemctl enable "$svc"
}

start_service_timeout() {
  local svc="$1"
  local seconds="${2:-10}"
  log "Start (timeout ${seconds}s): $svc"
  sudo timeout "$seconds" systemctl start "$svc"
}
