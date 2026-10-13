#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

if command -v paru >/dev/null 2>&1; then
  log "paru already installed"
  return 0
fi

# CachyOS dropped paru from its installer (June 2026) but still ships it in
# the [cachyos] repo. Prefer that over an AUR build when a repo has it.
if pacman -Si paru >/dev/null 2>&1; then
  log "Installing paru from the distro repo"
  sudo pacman -S --needed --noconfirm paru
  need_cmd paru
  return 0
fi

log "Installing paru-bin from the AUR"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmpdir/paru-bin"
(
  cd "$tmpdir/paru-bin"
  makepkg -si --noconfirm
)

need_cmd paru
