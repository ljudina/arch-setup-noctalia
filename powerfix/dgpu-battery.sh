#!/bin/bash
# Keep the NVIDIA dGPU asleep while on battery.
#
# rapl-powercap.sh only limits the CPU. The dGPU draws from the same pack
# and nothing caps it, so one app opening it on battery (LibreOffice OpenCL
# was the usual one) adds its draw on top of the CPU.
#
# The NVIDIA driver already powers the GPU down (runtime D3) whenever no
# process has it open, so the only thing that keeps it on is a client.
# While on battery this script checks every 15 s who holds the GPU, logs
# the holders and sends a desktop notification so the app can be closed.
# Nothing is killed.
#
# Do not "improve" this by removing the device from the PCI bus. That was
# tried (2026-11-17): the remove wakes the GPU, unbinds the driver and
# leaves the card powered with nothing left to suspend it (battery draw
# went from about 10.5 W suspended to about 15 W), and a rescan of the
# suspended bridge on AC did not bring the device back.
#
# Exits cleanly on machines without an NVIDIA GPU. Disable with
# DGPU_BATTERY_WATCH=0 in /etc/default/dgpu-battery.
# Log: journalctl -t dgpu-battery

INTERVAL=15
DGPU_BATTERY_WATCH=1
[ -f /etc/default/dgpu-battery ] && . /etc/default/dgpu-battery
[ "$DGPU_BATTERY_WATCH" = "1" ] || exit 0

say() { logger -t dgpu-battery "$*"; }

ac_online() {
    local ps
    for ps in /sys/class/power_supply/*; do
        if [ "$(cat "$ps/type" 2>/dev/null)" = "Mains" ]; then
            cat "$ps/online" 2>/dev/null || echo 1
            return
        fi
    done
    echo 1
}

# PIDs holding the NVIDIA device nodes or this GPU's DRM nodes open.
holders() {
    local pats=(-lname '/dev/nvidia*') n
    for n in "$1"/drm/*; do
        [ -e "$n" ] && pats+=(-o -lname "/dev/dri/${n##*/}")
    done
    find /proc/[0-9]*/fd -maxdepth 1 \( "${pats[@]}" \) 2>/dev/null | cut -d/ -f3 | sort -u
}

# Desktop notification to every logged-in user with a session bus.
notify() {
    local bus uid user
    command -v notify-send >/dev/null || return 0
    for bus in /run/user/*/bus; do
        [ -S "$bus" ] || continue
        uid=${bus#/run/user/}; uid=${uid%/bus}
        user=$(id -nu "$uid" 2>/dev/null) || continue
        runuser -u "$user" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
            notify-send -u critical -a "dgpu-battery" "$1" "$2" 2>/dev/null
    done
}

[ "$(ac_online)" = "0" ] || exit 0

devs=()
for d in /sys/bus/pci/drivers/nvidia/0000:*; do
    [ -e "$d" ] || continue
    case "$(cat "$d/class" 2>/dev/null)" in
        0x03*) devs+=("$(readlink -f "$d")") ;;
    esac
done
[ ${#devs[@]} -gt 0 ] || exit 0

last=''
while [ "$(ac_online)" = "0" ]; do
    names=''
    for d in "${devs[@]}"; do
        for p in $(holders "$d"); do
            names+="$(cat "/proc/$p/comm" 2>/dev/null)($p) "
        done
    done
    if [ "$names" != "$last" ]; then
        if [ -n "$names" ]; then
            say "on battery: dGPU kept awake by: $names"
            notify "NVIDIA GPU awake on battery" "Held by: $names"
        else
            say "on battery: dGPU has no clients, driver can power it down"
        fi
        last=$names
    fi
    sleep "$INTERVAL"
done
