#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

# WiFi
enable_service_now iwd.service

# Bluetooth
enable_service_now bluetooth.service

# Docker: enable only to avoid install hangs on some machines
enable_service docker.service
warn "Docker enabled. Start after reboot or manually: sudo systemctl start docker"

# Try to start docker but never hang the installer
start_service_timeout docker.service 10 || warn "Docker start timed out, skipping"
