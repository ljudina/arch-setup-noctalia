#!/usr/bin/env bash
set -euo pipefail

# USB automounting (Noctalia does not handle this)
udiskie --automount --file-manager nautilus &

# Wi-Fi tray (Noctalia does not replace iwgtk)
iwgtk -i &

# Auto switch power profile on AC plug/unplug
~/.config/hypr/scripts/ac-power-watcher.sh &

# foot terminal server (shared daemon backing all footclient instances)
if ! pgrep -x foot >/dev/null 2>&1; then
  foot --server &
fi

# Startup terminal on workspace 2. Placement is handled by a windowrule keyed on
# the custom app-id (the window is owned by the server PID, not footclient).
sock="$XDG_RUNTIME_DIR/foot-${WAYLAND_DISPLAY:-}.sock"
for _ in $(seq 1 50); do
  [ -S "$sock" ] && break
  sleep 0.1
done
footclient --app-id=foot-startup &
