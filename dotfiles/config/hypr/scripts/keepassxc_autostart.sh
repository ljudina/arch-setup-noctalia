#!/bin/bash


if pgrep -x "keepassxc" > /dev/null; then
    # Get JSON output of all clients
    clients=$(hyprctl clients -j)
    # Check for KeePassXC in special workspace "keepass"
    match=$(echo "$clients" | jq '.[] | select(.class == "org.keepassxc.KeePassXC" and .workspace.name == "special:keepass")')
    # Check if window is in special workspace (hidden)
    if [ -n "$match" ]; then
        # Window is hidden, show it on current workspace
        current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
        hyprctl dispatch movetoworkspace "$current_workspace",class:org.keepassxc.KeePassXC
        hyprctl dispatch focuswindow class:org.keepassxc.KeePassXC
    else
        # Window is visible, hide it
        hyprctl dispatch movetoworkspacesilent special:keepass,class:org.keepassxc.KeePassXC
    fi
else
    # Start KeePassXC
    keepassxc &
    # Wait for KeePassXC window to appear
    for i in {1..20}; do
        if hyprctl clients | grep -q "class: org.keepassxc.KeePassXC"; then
            break
        fi
        sleep 0.3
    done
fi
