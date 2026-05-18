#!/usr/bin/env bash
# Reconciles eDP-1 state with actual lid position.
# Safe to call anytime: on lid event, on monitor hotplug, on session start.

MONITOR="eDP-1"
LID_STATE_FILE=$(ls /proc/acpi/button/lid/*/state 2>/dev/null | head -n1)

if [[ -z "$LID_STATE_FILE" ]]; then
    echo "No lid state file found" >&2
    exit 1
fi

# "state:      open" or "state:      closed"
LID=$(awk '{print $2}' "$LID_STATE_FILE")

# Count external monitors (anything that isn't eDP-1)
EXTERNAL_COUNT=$(hyprctl monitors -j | jq "[.[] | select(.name != \"$MONITOR\")] | length")

if [[ "$LID" == "closed" ]]; then
    if [[ "$EXTERNAL_COUNT" -gt 0 ]]; then
        hyprctl keyword monitor "$MONITOR, disable"
    fi
    # If no external monitor, leave eDP-1 alone — don't lock yourself out
else
    hyprctl keyword monitor "$MONITOR, preferred, auto, 1"
fi
