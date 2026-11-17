#!/bin/bash
# Flight recorder for hard power-offs. Appends one line per second (every
# 10 s on AC) with battery draw, battery voltage, CPU package power, the
# hottest thermal zone, fan speed and the dGPU power state, and flushes it
# to disk right away. After an unexplained power-off the last lines before
# the next "# start" marker show what the machine was doing when it died.
#
# Nothing here wakes the dGPU: only sysfs is read, never nvidia-smi.
# bat_w is the whole machine, so bat_w minus cpu_w is everything else
# (dGPU, display, SSD, radios).
#
# Exits cleanly on machines without a battery.

export LC_ALL=C
LOG=${POWER_TRACE_LOG:-/var/log/power-trace.log}
MAX_BYTES=$((16 * 1024 * 1024))   # then rotate to $LOG.1 (about two days at 1 Hz)
RAPL=/sys/class/powercap/intel-rapl:0

# rd VAR FILE: read the first line of FILE into VAR without forking.
rd() {
    { read -r "$1" < "$2"; } 2>/dev/null || printf -v "$1" ''
}

# fix VAR MICRO: format a micro-unit integer (uW, uV) with two decimals.
fix() {
    printf -v "$1" '%d.%02d' $(( $2 / 1000000 )) $(( ($2 % 1000000) / 10000 ))
}

BAT='' AC=''
for ps in /sys/class/power_supply/*; do
    rd t "$ps/type"
    rd scope "$ps/scope"
    case $t in
        Battery) [ -z "$BAT" ] && [ "$scope" != "Device" ] && BAT=$ps ;;
        Mains)   [ -z "$AC" ] && AC=$ps ;;
    esac
done
[ -n "$BAT" ] || exit 0

# All thermal zones, to report the hottest one each tick. Board sensors
# (SEN1-4 on ThinkPads) trip a shutdown at a much lower temperature than
# the CPU does, so the CPU package alone would miss an overheat.
ZONES=() ZNAMES=()
for tz in /sys/class/thermal/thermal_zone*; do
    rd t "$tz/type"
    case $t in ''|INT3400*) continue ;; esac
    ZONES+=("$tz/temp") ZNAMES+=("${t// /_}")
done

FAN=''
for h in /sys/class/hwmon/hwmon*; do
    rd t "$h/name"
    [ "$t" = "thinkpad" ] && [ -e "$h/fan1_input" ] && FAN=$h/fan1_input && break
done

rd emax "$RAPL/max_energy_range_uj"
rd boot_id /proc/sys/kernel/random/boot_id
printf '# start %(%FT%T)T boot_id=%s\n' -1 "$boot_id" >> "$LOG"

prev_e='' prev_t='' tick=0
while :; do
    rd ac "$AC/online"
    rd status "$BAT/status"
    rd pct "$BAT/capacity"
    rd uv "$BAT/voltage_now"
    rd uw "$BAT/power_now"
    if [ -z "$uw" ]; then
        # Some packs report current instead of power.
        rd ua "$BAT/current_now"
        [ -n "$ua" ] && [ -n "$uv" ] && uw=$(( ua * (uv / 1000) / 1000 ))
    fi
    bat_w=- bat_v=-
    [ -n "$uw" ] && fix bat_w "$uw"
    [ -n "$uv" ] && fix bat_v "$uv"

    # CPU package power from the RAPL energy counter (root only).
    now=${EPOCHREALTIME/./}
    cpu_w=-
    rd e "$RAPL/energy_uj"
    if [ -n "$e" ]; then
        if [ -n "$prev_e" ]; then
            de=$(( e - prev_e ))
            (( de < 0 )) && de=$(( de + ${emax:-0} ))
            dt=$(( now - prev_t ))
            (( dt > 0 )) && fix cpu_w $(( de * 1000000 / dt ))
        fi
        prev_e=$e prev_t=$now
    fi

    hot=- hot_mc=-1
    for i in "${!ZONES[@]}"; do
        rd mc "${ZONES[i]}"
        [ -n "$mc" ] && (( mc > hot_mc )) && hot_mc=$mc && hot=${ZNAMES[i]}:$(( mc / 1000 ))
    done

    fan=-
    [ -n "$FAN" ] && rd fan "$FAN"

    # "none" means no NVIDIA device is bound, e.g. dgpu-battery.sh removed it.
    dgpu=none
    for d in /sys/bus/pci/drivers/nvidia/0000:*; do
        [ -e "$d" ] || continue
        rd dgpu "$d/power/runtime_status"
        break
    done

    printf '%(%FT%T)T ac=%s status=%s pct=%s bat_w=%s bat_v=%s cpu_w=%s hot=%s fan=%s dgpu=%s\n' \
        -1 "${ac:--}" "${status// /_}" "${pct:--}" "$bat_w" "$bat_v" "$cpu_w" "$hot" "${fan:--}" "${dgpu:--}" >> "$LOG"
    sync -d "$LOG"

    if (( ++tick % 300 == 0 )); then
        size=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
        (( size > MAX_BYTES )) && mv -f "$LOG" "$LOG.1"
    fi

    if [ "$ac" = "0" ]; then sleep 1; else sleep 10; fi
done
