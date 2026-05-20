#!/usr/bin/env bash
set -euo pipefail

# USB automounting (Noctalia does not handle this)
udiskie --automount --file-manager nautilus &

# Wi-Fi tray (Noctalia does not replace iwgtk)
iwgtk -i &

# Auto switch power profile on AC plug/unplug
~/.config/hypr/scripts/ac-power-watcher.sh &
