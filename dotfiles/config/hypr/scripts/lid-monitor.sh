#!/usr/bin/env bash
# Reconciles eDP-1 state with actual lid position.
# Safe to call anytime: on lid event, on monitor hotplug, on session start.

LOG=/tmp/lid-monitor.log
log() { printf '[%s] lid-monitor: %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG"; }

log "invoked (caller=${1:-unknown})"

MONITOR="eDP-1"
LID_STATE_FILE=$(ls /proc/acpi/button/lid/*/state 2>/dev/null | head -n1)

if [[ -z "$LID_STATE_FILE" ]]; then
    echo "No lid state file found" >&2
    exit 1
fi

# "state:      open" or "state:      closed"
LID=$(awk '{print $2}' "$LID_STATE_FILE")

# Settle delay so hyprctl monitors reflects post-hotplug state.
# 0.3s proved too short when a lid+unplug happen in the same second — bump to 1s.
sleep 1

# Count external monitors (anything that isn't eDP-1)
EXTERNAL_COUNT=$(hyprctl monitors -j | jq "[.[] | select(.name != \"$MONITOR\")] | length")
log "lid=$LID external_count=$EXTERNAL_COUNT"

# Re-enable an internal panel that was previously disabled.
# Three-tier escalation, because Hyprland sometimes refuses to clear a prior
# "disable" flag through hyprctl keyword alone:
#   1. preferred,auto,1  (the normal form)
#   2. preferred,0x0,1   (explicit position — works in some stuck-disable states)
#   3. hyprctl reload    (re-reads hyprland.conf where monitor=eDP-1 is static)
# Logs the .disabled flag at each step so we can see which tier actually worked.
is_disabled() {
    hyprctl monitors all -j | jq -r --arg m "$MONITOR" \
        '.[] | select(.name == $m) | .disabled'
}
enable_monitor() {
    local d
    log "  step1: hyprctl keyword monitor $MONITOR, preferred, auto, 1"
    hyprctl keyword monitor "$MONITOR, preferred, auto, 1"
    sleep 0.3
    d=$(is_disabled)
    log "  step1 result: disabled=$d"
    if [[ "$d" == "true" ]]; then
        log "  step2: hyprctl keyword monitor $MONITOR, preferred, 0x0, 1"
        hyprctl keyword monitor "$MONITOR, preferred, 0x0, 1"
        sleep 0.3
        d=$(is_disabled)
        log "  step2 result: disabled=$d"
    fi
    # Guard step3 against recursion: hyprland.conf has `exec = lid-monitor.sh`,
    # which re-fires the script on every reload. Skip step3 if we just did it.
    local guard=/tmp/lid-monitor-reload.guard
    local guard_age=999
    if [[ -f "$guard" ]]; then
        guard_age=$(( $(date +%s) - $(stat -c %Y "$guard") ))
    fi
    if [[ "$d" == "true" ]] && [[ "$guard_age" -gt 5 ]]; then
        log "  step3: hyprctl reload (last-resort)"
        touch "$guard"
        hyprctl reload >/dev/null
        sleep 0.5
        d=$(is_disabled)
        log "  step3 result: disabled=$d"
    elif [[ "$d" == "true" ]]; then
        log "  step3 skipped (reload guard active, age=${guard_age}s)"
    fi
    hyprctl dispatch dpms on "$MONITOR" >/dev/null 2>&1 || true
}

if [[ "$EXTERNAL_COUNT" -eq 0 ]]; then
    # No externals: internal panel must stay on, even with the lid closed —
    # Hyprland needs at least one active monitor, and opening the lid then "just works".
    log "action: enable $MONITOR (no externals)"
    enable_monitor
elif [[ "$LID" == "closed" ]]; then
    log "action: disable $MONITOR (lid closed + externals present)"
    hyprctl keyword monitor "$MONITOR, disable"
else
    log "action: enable $MONITOR (lid open + externals present)"
    enable_monitor
fi
