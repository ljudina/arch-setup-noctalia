#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

if command -v paru >/dev/null 2>&1; then
  log "paru already installed"
  return 0
fi

log "Installing paru-bin"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmpdir/paru-bin"
(
  cd "$tmpdir/paru-bin"
  makepkg -si --noconfirm
)

need_cmd paru
