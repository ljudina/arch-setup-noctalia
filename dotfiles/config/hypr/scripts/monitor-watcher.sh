#!/usr/bin/env bash
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
while read -r line; do
    case "$line" in
        monitoradded*|monitoraddedv2*|monitorremoved*|monitorremovedv2*)
            ~/.config/hypr/scripts/lid-monitor.sh
            ;;
    esac
done
