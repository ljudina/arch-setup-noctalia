#!/usr/bin/env bash
# Launch Thorium on Wayland regardless of which AUR build is installed.
#
# The CPU-specific AUR packages (thorium-browser-avx2-bin, -avx-bin, -sse4-bin)
# ship their binary under a suffixed name, while thorium-browser-bin ships
# plain "thorium-browser". Resolve whichever exists so hyprland.lua and mail.sh
# do not depend on the package choice.
#
# Thorium's wrapper reads $XDG_CONFIG_HOME/thorium/thorium-flags.conf only when
# XDG_CONFIG_HOME is set, so default it here; 70-dotfiles.sh seeds that file
# with the same Wayland flags for launches that bypass this script (launcher).
set -euo pipefail

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

for candidate in thorium-browser-avx2 thorium-browser-avx thorium-browser-sse4 thorium-browser; do
  if command -v "$candidate" >/dev/null 2>&1; then
    exec "$candidate" --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
  fi
done

echo "browser.sh: no thorium-browser binary found" >&2
exit 127
