#!/usr/bin/env bash
# fleetmon_status — read-only health of the fleet-monitor dashboard. The CHECK always succeeds (exit 0); the
# health lives in the RECORD (status.json): supervisor_loaded, serving, snapshot_fresh. A frozen-but-alive
# loop (mirror stops advancing) and a never-started loop (no heartbeat mark) both read as NOT fresh. Read-only.
#
# Vars (optional): LABEL, PORT, HOST_BIND ("auto"->tailnet), MIRROR_DIR, HEARTBEAT_NODE, MIRROR_INTERVAL, FLEET_CONFIG, RECORD_STORE
set -euo pipefail

PORT="${PORT:-8787}"
HOST_BIND="${HOST_BIND:-auto}"
MIRROR_DIR="${MIRROR_DIR:-$HOME/.cyberware/fleet-ledgers}"
MIRROR_INTERVAL="${MIRROR_INTERVAL:-15}"
LABEL="${LABEL:-com.cyberware.fleetdash}"
FLEET_CONFIG="${FLEET_CONFIG:-$HOME/.cyberware/fleet.json}"
REC="${RECORD_STORE:-.}"

# validate operator-supplied vars before any use (launchctl args, curl/stat targets, a python read)
_id(){   case "${1:-}" in ''|*[!A-Za-z0-9._-]*) return 1;; esac; }
_num(){  case "${1:-}" in ''|*[!0-9]*) return 1;; esac; }
_ip(){   case "${1:-}" in ''|*[!0-9a-fA-F:.]*) return 1;; esac; }
_path(){ case "${1:-}" in *[!A-Za-z0-9._/\ -]*) return 1;; esac; }
_id   "$LABEL"           || { echo "fleetmon_status: LABEL unsafe" >&2; exit 2; }
_num  "$PORT"            || { echo "fleetmon_status: PORT must be an integer" >&2; exit 2; }
_num  "$MIRROR_INTERVAL" || { echo "fleetmon_status: MIRROR_INTERVAL must be an integer" >&2; exit 2; }
_path "$MIRROR_DIR"      || { echo "fleetmon_status: MIRROR_DIR has a shell metachar / tilde" >&2; exit 2; }
_path "$FLEET_CONFIG"    || { echo "fleetmon_status: FLEET_CONFIG has a shell metachar / tilde" >&2; exit 2; }
[ -z "${HEARTBEAT_NODE:-}" ] || _id "$HEARTBEAT_NODE" || { echo "fleetmon_status: HEARTBEAT_NODE unsafe" >&2; exit 2; }

if [ "$HOST_BIND" = "auto" ]; then
  ts=$(command -v tailscale || echo /Applications/Tailscale.app/Contents/MacOS/Tailscale)
  HOST_BIND="$("$ts" ip -4 2>/dev/null | head -1)"; : "${HOST_BIND:=127.0.0.1}"
fi
_ip "$HOST_BIND" || { echo "fleetmon_status: HOST_BIND is not an IP literal" >&2; exit 2; }

# heartbeat node = first roster node unless pinned — FLEET_CONFIG passed as ARGV, never string-interpolated
HEARTBEAT_NODE="${HEARTBEAT_NODE:-$(python3 -c 'import json,sys
try:
    print((json.load(open(sys.argv[1])).get("nodes") or [{}])[0].get("name",""))
except Exception:
    pass' "$FLEET_CONFIG" 2>/dev/null || true)}"

# supervisor loaded? (no launchctl/systemctl at all -> unknown, reported truthfully in the record)
loaded="none"
if command -v launchctl >/dev/null 2>&1; then
  launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 && loaded="yes" || loaded="no"
elif command -v systemctl >/dev/null 2>&1; then
  systemctl --user is-active "${LABEL}.service" >/dev/null 2>&1 && loaded="yes" || loaded="no"
fi

# serving? require a fleetdash-identifying marker so any 200-responder isn't mistaken for the dashboard
serving="no"
curl -fsS -m5 "http://${HOST_BIND}:${PORT}/" 2>/dev/null | grep -qiE 'central mirror|cyberware .* fleet' && serving="yes"

# snapshot freshness: no heartbeat node OR no mark file => NOT fresh (a never-started/wedged loop must not read healthy).
# fleetdash writes the mirror dir through _safe (non [A-Za-z0-9_-] -> _), so sanitize the node the same way for the path.
hb_safe="$(printf '%s' "${HEARTBEAT_NODE:-}" | tr -c 'A-Za-z0-9_-' '_')"
mark="${MIRROR_DIR}/${hb_safe}/index.json"; age="-1"; fresh="no_heartbeat"
if [ -n "${HEARTBEAT_NODE:-}" ] && [ -f "$mark" ]; then
  mt=$(stat -c %Y "$mark" 2>/dev/null || stat -f %m "$mark" 2>/dev/null)
  age=$(( $(date +%s) - ${mt:-0} ))
  [ "$age" -le $(( MIRROR_INTERVAL * 6 + 30 )) ] && fresh="yes" || fresh="STALE"
fi

# healthy = loaded + serving + a genuinely fresh loop; surfaced as a FIELD, not the exit code (the check itself succeeded)
healthy="no"; [ "$loaded" = "yes" ] && [ "$serving" = "yes" ] && [ "$fresh" = "yes" ] && healthy="yes"

mkdir -p "$REC"
python3 -c 'import json,sys
json.dump({"healthy":sys.argv[1],"supervisor_loaded":sys.argv[2],"serving":sys.argv[3],"snapshot_fresh":sys.argv[4],
"mirror_age_s":int(sys.argv[5]),"label":sys.argv[6],"bind":sys.argv[7],"port":int(sys.argv[8]),
"heartbeat_node":sys.argv[9]}, open(sys.argv[10],"w"), indent=1)' \
  "$healthy" "$loaded" "$serving" "$fresh" "$age" "$LABEL" "$HOST_BIND" "$PORT" "${HEARTBEAT_NODE:-?}" "$REC/status.json"
echo "fleetmon_status: healthy=$healthy (loaded=$loaded serving=$serving snapshot=$fresh, mirror age ${age}s) @ ${HOST_BIND}:${PORT}"
exit 0
