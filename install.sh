#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"

run_step() {
  local step="$1"
  log "Running: $step"
  # shellcheck disable=SC1090
  source "$ROOT_DIR/scripts/$step"
}

run_step "00-prereq.sh"
run_step "10-pacman.sh"
run_step "20-paru.sh"
run_step "30-aur.sh"
run_step "50-ohmyzsh.sh"
run_step "60-tools.sh"
run_step "65-nvim.sh"
run_step "70-dotfiles.sh"
run_step "40-services.sh"

log "All done."
warn "If you changed default shell to zsh, log out and log back in."
warn "If you want docker without sudo: sudo usermod -aG docker $USER (then re-login)."
