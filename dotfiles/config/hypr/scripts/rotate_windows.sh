#!/bin/bash

# Number of windows in the current workspace
count=$(hyprctl clients -j | jq '[.[] | select(.workspace.id == '"$(hyprctl activeworkspace -j | jq '.id')"') ] | length')

# Exit if fewer than 2 windows
[ "$count" -lt 2 ] && exit

# Perform (count - 1) swaps to rotate the layout
for ((i = 0; i < count - 1; i++)); do
    hyprctl dispatch swapwindow r
done
