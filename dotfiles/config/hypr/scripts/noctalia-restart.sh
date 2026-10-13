#!/usr/bin/env bash
# Restart the Noctalia shell safely.
#
# Noctalia is also the ext-session-lock client. Killing it while the session is
# locked drops the lock: Hyprland reports "lock app crashed", shows a red
# screen, and the restarted shell does not re-lock on its own. So refuse to
# restart while locked, and relaunch through Hyprland so the new process gets
# the compositor's environment (same as the hyprland.start exec).
set -euo pipefail

if noctalia msg status 2>/dev/null | grep -q '"locked": *true'; then
  echo "noctalia-restart: session is locked, refusing to restart the lock client" >&2
  exit 1
fi
if [[ "$(loginctl show-session "${XDG_SESSION_ID:-self}" -p LockedHint --value 2>/dev/null)" == "yes" ]]; then
  echo "noctalia-restart: logind reports the session locked, refusing to restart" >&2
  exit 1
fi

pkill -x noctalia || true
for _ in $(seq 1 50); do
  pgrep -x noctalia >/dev/null || break
  sleep 0.1
done

hyprctl dispatch 'hl.dsp.exec_cmd("noctalia")' >/dev/null

for _ in $(seq 1 50); do
  if noctalia msg status >/dev/null 2>&1; then
    echo "noctalia-restart: shell is back (pid $(pgrep -x noctalia | head -1))"
    exit 0
  fi
  sleep 0.2
done
echo "noctalia-restart: shell did not answer within 10s, check ~/.cache/noctalia/noctalia.log" >&2
exit 1
