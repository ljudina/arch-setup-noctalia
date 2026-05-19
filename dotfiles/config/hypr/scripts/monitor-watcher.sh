#!/usr/bin/env bash
# Watches two independent sources and reconciles eDP-1 on either:
#   1. Hyprland IPC monitor add/remove events (dock plug/unplug)
#   2. /proc lid-state changes (our own poller, because Hyprland's bindl
#      lid-switch event is sometimes dropped when it collides with a monitor
#      hotplug cascade)
LOG=/tmp/lid-monitor.log
log() { printf '[%s] watcher: %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG"; }

# Independent lid poller — cheap (one /proc read per second).
lid_poller() {
    local lid_file prev cur
    lid_file=$(ls /proc/acpi/button/lid/*/state 2>/dev/null | head -n1)
    if [[ -z "$lid_file" ]]; then
        log "lid-poller: no /proc lid file, exiting poller"
        return
    fi
    prev=$(awk '{print $2}' "$lid_file")
    log "lid-poller: started (initial state=$prev)"
    while true; do
        sleep 1
        cur=$(awk '{print $2}' "$lid_file")
        if [[ "$cur" != "$prev" ]]; then
            log "lid-poller: state change $prev -> $cur"
            ~/.config/hypr/scripts/lid-monitor.sh "lid-poller" &
            prev=$cur
        fi
    done
}

log "watcher started (pid=$$)"
lid_poller &
LID_POLLER_PID=$!
trap "kill $LID_POLLER_PID 2>/dev/null" EXIT

# Auto-restart loop so the IPC watcher survives Hyprland restarts / socat exits.
while true; do
    socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
    while read -r line; do
        # Log EVERY event so we can see what Hyprland actually emits on dock dis/connect
        log "event: ${line%%>>*}"
        case "$line" in
            monitoradded*|monitoraddedv2*|monitorremoved*|monitorremovedv2*)
                log "  -> dispatching lid-monitor.sh"
                ~/.config/hypr/scripts/lid-monitor.sh "watcher" &
                ;;
        esac
    done
    log "socat exited, restarting in 1s"
    sleep 1
done
