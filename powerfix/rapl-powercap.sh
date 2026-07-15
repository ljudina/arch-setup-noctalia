#!/bin/bash
# Cap CPU package power (MSR RAPL) on battery, restore firmware limits on AC.
# Prevents hard power-offs when CPU peak draw exceeds what the battery pack
# can deliver (seen on ThinkPad P14s Gen 4 / i7-1370P during video calls).
#
# Portable: detects the Mains supply by type, captures this machine's own
# firmware limits at boot, and derives battery caps as a fraction of them.
# Exits cleanly on hardware without Intel RAPL (e.g. AMD), so it is safe
# to install everywhere.
#
# Only intel-rapl:0 (MSR) is touched; intel-rapl-mmio:0 stays under
# power-profiles-daemon control. Effective limit = min(MSR, MMIO).

RAPL=/sys/class/powercap/intel-rapl:0
STOCK=/run/rapl-powercap.stock

[ -d "$RAPL" ] || exit 0

# Battery caps as percent of firmware defaults.
# Override in /etc/default/rapl-powercap if a machine needs different values.
# PL2/PL4 were 60/50 originally; a hard power-off still occurred on battery
# during a video call with those caps (2026-07-15), so burst and peak are
# now held close to the sustained limit. Millisecond peaks trip the pack's
# overcurrent cutoff even when the sustained draw is fine.
BAT_PL1_PCT=40   # sustained
BAT_PL2_PCT=45   # short burst
BAT_PL4_PCT=30   # instantaneous peak
[ -f /etc/default/rapl-powercap ] && . /etc/default/rapl-powercap

# Find the AC adapter; its name differs across vendors (AC, ACAD, ADP1, ...)
AC_ONLINE=1
for ps in /sys/class/power_supply/*; do
    if [ "$(cat "$ps/type" 2>/dev/null)" = "Mains" ]; then
        AC_ONLINE=$(cat "$ps/online" 2>/dev/null || echo 1)
        break
    fi
done

# First run after boot: remember the firmware defaults. /run survives
# suspend (limits reset on resume, cache does not) and clears on reboot.
if [ ! -f "$STOCK" ]; then
    for c in 0 1 2; do
        f="$RAPL/constraint_${c}_power_limit_uw"
        [ -f "$f" ] && echo "$c $(cat "$f")"
    done > "$STOCK"
fi

while read -r c stock; do
    f="$RAPL/constraint_${c}_power_limit_uw"
    [ -w "$f" ] || continue
    if [ "$AC_ONLINE" = "0" ]; then
        case $c in
            0) pct=$BAT_PL1_PCT ;;
            1) pct=$BAT_PL2_PCT ;;
            *) pct=$BAT_PL4_PCT ;;
        esac
        echo $(( stock * pct / 100 )) > "$f"
    else
        echo "$stock" > "$f"
    fi
done < "$STOCK"

MODE=AC; [ "$AC_ONLINE" = "0" ] && MODE=battery
logger -t rapl-powercap "applied $MODE limits: $(cat "$RAPL"/constraint_*_power_limit_uw 2>/dev/null | tr '\n' ' ')uW"
