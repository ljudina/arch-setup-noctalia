#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

# On-battery CPU power cap: prevents hard power-offs when CPU peak draw
# exceeds what the battery can deliver (see powerfix/rapl-powercap.sh).
# The script no-ops on hardware without Intel RAPL, so installing it
# everywhere is safe.
#
# Also installed: dgpu-battery (reports what keeps the NVIDIA dGPU awake on battery, no-op
# without one) and power-trace (per-second power log for diagnosing
# power-offs, no-op without a battery).

log "Installing on-battery CPU power cap (powerfix)"

sudo install -m 755 "$ROOT_DIR/powerfix/rapl-powercap.sh" /usr/local/bin/rapl-powercap.sh
sudo install -m 644 "$ROOT_DIR/powerfix/99-rapl-powercap.rules" /etc/udev/rules.d/99-rapl-powercap.rules
sudo install -m 644 "$ROOT_DIR/powerfix/rapl-powercap.service" /etc/systemd/system/rapl-powercap.service
sudo install -m 755 "$ROOT_DIR/powerfix/rapl-powercap-sleep.sh" /usr/lib/systemd/system-sleep/rapl-powercap.sh

sudo install -m 755 "$ROOT_DIR/powerfix/dgpu-battery.sh" /usr/local/bin/dgpu-battery.sh
sudo install -m 644 "$ROOT_DIR/powerfix/99-dgpu-battery.rules" /etc/udev/rules.d/99-dgpu-battery.rules
sudo install -m 644 "$ROOT_DIR/powerfix/dgpu-battery.service" /etc/systemd/system/dgpu-battery.service

sudo install -m 755 "$ROOT_DIR/powerfix/power-trace.sh" /usr/local/bin/power-trace.sh
sudo install -m 644 "$ROOT_DIR/powerfix/power-trace.service" /etc/systemd/system/power-trace.service

sudo udevadm control --reload
sudo systemctl daemon-reload
enable_service_now rapl-powercap.service
enable_service_now dgpu-battery.service
enable_service_now power-trace.service
# Pick up script changes on a re-run (enable --now leaves a running unit alone).
sudo systemctl restart dgpu-battery.service power-trace.service

if [ ! -d /sys/class/powercap/intel-rapl:0 ]; then
    warn "No Intel RAPL on this machine; powerfix installed but inactive"
fi
