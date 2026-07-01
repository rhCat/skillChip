#!/usr/bin/env bash
# fleetmon_down — stop + unregister the supervised fleet-monitor dashboard and remove the rendered artifacts.
# The durable mirror (MIRROR_DIR) is PRESERVED — teardown is about the service, not the recorded history.
#
# Vars (optional): LABEL, FLEET_HOME, KEEP_SCRIPTS=1 (leave the rendered launcher/watchdog on disk), RECORD_STORE
set -euo pipefail

LABEL="${LABEL:-com.cyberware.fleetdash}"
FLEET_HOME="${FLEET_HOME:-$HOME/fleet}"
REC="${RECORD_STORE:-.}"
# LABEL reaches launchctl/systemctl args AND rm paths — validate before use (no injection/traversal)
case "${LABEL:-}" in ''|*[!A-Za-z0-9._-]*) echo "fleetmon_down: LABEL unsafe" >&2; exit 2;; esac
case "${FLEET_HOME:-}" in *[!A-Za-z0-9._/~\ -]*) echo "fleetmon_down: FLEET_HOME has a shell metachar" >&2; exit 2;; esac
removed=()

if command -v launchctl >/dev/null 2>&1; then
  U="$(id -u)"
  for lbl in "$LABEL" "${LABEL}-watchdog"; do
    launchctl bootout "gui/$U/$lbl" 2>/dev/null || launchctl unload "$HOME/Library/LaunchAgents/${lbl}.plist" 2>/dev/null || true
    for f in "$HOME/Library/LaunchAgents/${lbl}.plist"; do [ -f "$f" ] && rm -f "$f" && removed+=("$f"); done
  done
elif command -v systemctl >/dev/null 2>&1; then
  UD="$HOME/.config/systemd/user"
  systemctl --user disable --now "${LABEL}.service" "${LABEL}-watchdog.timer" 2>/dev/null || true
  for f in "$UD/${LABEL}.service" "$UD/${LABEL}-watchdog.service" "$UD/${LABEL}-watchdog.timer"; do
    [ -f "$f" ] && rm -f "$f" && removed+=("$f")
  done
  systemctl --user daemon-reload 2>/dev/null || true
fi

# optionally drop the rendered launcher/watchdog (the unit already stopped the process + freed the port)
if [ "${KEEP_SCRIPTS:-0}" != "1" ]; then
  for f in "$FLEET_HOME/fleetdash.sh" "$FLEET_HOME/fleetdash-watchdog.sh"; do
    [ -f "$f" ] && rm -f "$f" && removed+=("$f")
  done
fi

mkdir -p "$REC"
# pass paths as ARGV (no python-string interpolation); build removed[] only when non-empty so it records [] not [""]
args=("$LABEL" "$REC/down.json")
[ ${#removed[@]} -gt 0 ] && args+=("${removed[@]}")
python3 -c 'import json,sys
json.dump({"ok":True,"label":sys.argv[1],"removed":sys.argv[3:]}, open(sys.argv[2],"w"), indent=1)' \
  "${args[@]}"
echo "fleetmon_down: $LABEL stopped + unregistered; ${#removed[@]} artifact(s) removed (mirror preserved)"
