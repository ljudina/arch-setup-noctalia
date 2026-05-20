#!/usr/bin/env bash
# Auto-switches power-profiles-daemon profile based on AC adapter state.
# AC online -> performance, AC offline -> power-saver.
# Only fires on AC state CHANGES — manual profile selection (e.g. via noctalia)
# sticks until the next plug/unplug event.
set -euo pipefail

AC_FILE="/sys/class/power_supply/AC/online"
STATE_FILE="/tmp/ac-power-watcher.state"
LOG="/tmp/ac-power-watcher.log"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; }

command -v powerprofilesctl >/dev/null || { log "powerprofilesctl missing, exit"; exit 0; }
[[ -r "$AC_FILE" ]] || { log "no $AC_FILE, exit"; exit 0; }

apply() {
  local online="$1" profile
  [[ "$online" == "1" ]] && profile=performance || profile=power-saver

  local last=""
  [[ -r "$STATE_FILE" ]] && last=$(<"$STATE_FILE")
  [[ "$online" == "$last" ]] && return 0

  # One retry covers the boot-time race where PPD isn't D-Bus-ready yet.
  if ! powerprofilesctl set "$profile" 2>>"$LOG"; then
    sleep 2
    powerprofilesctl set "$profile" 2>>"$LOG" || { log "set $profile FAILED"; return 1; }
  fi
  printf '%s' "$online" >"$STATE_FILE"
  log "set $profile (ac=$online)"
}

# Initial state on launch.
apply "$(<"$AC_FILE")" || true

# Event loop — udevadm emits a block per event, terminated by a blank line.
udevadm monitor --subsystem-match=power_supply --property 2>/dev/null \
  | while read -r line; do
      if [[ -z "$line" ]]; then
        apply "$(<"$AC_FILE")" || true
      fi
    done
