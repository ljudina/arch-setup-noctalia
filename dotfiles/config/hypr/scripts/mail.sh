#!/usr/bin/env bash
# Launch the mail client for the startup workspace.
#
# Prefers the Outlook PWA that Chrome installs as a desktop entry. On a machine
# without that entry, install a Gmail PWA desktop entry (a browser --app window,
# the same shape Chromium generates for "Create shortcut") and launch that, so
# the mail workspace is never empty. Both window classes are pinned to
# workspace 3 in hyprland.lua (outlook-pwa-workspace / gmail-app-workspace).
set -euo pipefail

apps_dir="$HOME/.local/share/applications"
outlook_entry="${OUTLOOK_ENTRY:-$apps_dir/chrome-faolnafnngnfdaknnbpnkhgohbobgegn-Default.desktop}"
gmail_entry="${GMAIL_ENTRY:-$apps_dir/gmail-pwa.desktop}"
browser="thorium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland"

if [ -f "$outlook_entry" ]; then
  exec gio launch "$outlook_entry"
fi

if [ ! -f "$gmail_entry" ]; then
  mkdir -p "$(dirname "$gmail_entry")"
  cat > "$gmail_entry" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Gmail (PWA)
Comment=Gmail as a standalone browser app window
Exec=$browser --app=https://mail.google.com %U
Icon=internet-mail
Terminal=false
Categories=Network;Email;
MimeType=x-scheme-handler/mailto;
StartupWMClass=thorium-mail.google.com__-Default
DESKTOP
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$(dirname "$gmail_entry")" || true
fi

exec gio launch "$gmail_entry"
