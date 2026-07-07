#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

# On-battery CPU power cap: prevents hard power-offs when CPU peak draw
# exceeds what the battery can deliver (see powerfix/rapl-powercap.sh).
# The script no-ops on hardware without Intel RAPL, so installing it
# everywhere is safe.

log "Installing on-battery CPU power cap (powerfix)"

sudo install -m 755 "$ROOT_DIR/powerfix/rapl-powercap.sh" /usr/local/bin/rapl-powercap.sh
sudo install -m 644 "$ROOT_DIR/powerfix/99-rapl-powercap.rules" /etc/udev/rules.d/99-rapl-powercap.rules
sudo install -m 644 "$ROOT_DIR/powerfix/rapl-powercap.service" /etc/systemd/system/rapl-powercap.service
sudo install -m 755 "$ROOT_DIR/powerfix/rapl-powercap-sleep.sh" /usr/lib/systemd/system-sleep/rapl-powercap.sh

sudo udevadm control --reload
sudo systemctl daemon-reload
enable_service_now rapl-powercap.service

if [ ! -d /sys/class/powercap/intel-rapl:0 ]; then
    warn "No Intel RAPL on this machine; powerfix installed but inactive"
fi
