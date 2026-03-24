#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

pac_install_file "$ROOT_DIR/config/pacman.txt"
pac_install_file "$ROOT_DIR/config/fonts.txt"
