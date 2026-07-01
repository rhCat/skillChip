#!/usr/bin/env bash
# fleetmon_deploy — stand up the fleet-monitor dashboard (fleetdash) as a SUPERVISED, self-healing service.
# Fully parameterized + desensitized: no host, node, path, or interpreter is baked in — every knob is a var
# with a sane default. OS-detected: launchd (macOS) or a systemd --user unit (Linux). Renders three artifacts
# into the operator's OWN deployment dir (never the repo): the launcher, a freeze-watchdog, and the unit.
#
# Vars (all optional; ${VAR:-default}):
#   PORT            dashboard port                         (8787)
#   HOST_BIND       interface to bind; "auto" = tailnet IP (auto -> `tailscale ip -4`; falls back 127.0.0.1)
#   PYTHON          interpreter with cyberware importable  (python3)
#   CYBERWARE_ROOT  the cyberware checkout                 ($HOME/hunyuan/cyberware)
#   FLEET_CONFIG    the fleet roster json                  ($HOME/.cyberware/fleet.json)
#   MIRROR_DIR      durable mirror dir                     ($HOME/.cyberware/fleet-ledgers)
#   MIRROR_INTERVAL background sweep seconds               (15)
#   HEARTBEAT_NODE  node whose mirror mtime = the loop's heartbeat (default: first node in FLEET_CONFIG)
#   LABEL           service label / unit name              (com.cyberware.fleetdash)
#   FLEET_HOME      where rendered scripts live            ($HOME/fleet)
#   LOG_DIR         log dir                                ($HOME/.cyberware)
#   RECORD_STORE    (provided by the runtime) value-free deploy record sink
set -euo pipefail

PORT="${PORT:-8787}"
HOST_BIND="${HOST_BIND:-auto}"
PYTHON="${PYTHON:-python3}"
CYBERWARE_ROOT="${CYBERWARE_ROOT:-$HOME/hunyuan/cyberware}"
FLEET_CONFIG="${FLEET_CONFIG:-$HOME/.cyberware/fleet.json}"
MIRROR_DIR="${MIRROR_DIR:-$HOME/.cyberware/fleet-ledgers}"
MIRROR_INTERVAL="${MIRROR_INTERVAL:-15}"
LABEL="${LABEL:-com.cyberware.fleetdash}"
FLEET_HOME="${FLEET_HOME:-$HOME/fleet}"
LOG_DIR="${LOG_DIR:-$HOME/.cyberware}"
REC="${RECORD_STORE:-.}"

_ts()  { python3 -c 'import time;print(time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()))'; }
_tailnet_ip() {
  local ts; ts=$(command -v tailscale || echo /Applications/Tailscale.app/Contents/MacOS/Tailscale)
  "$ts" ip -4 2>/dev/null | head -1
}

# resolve HOST_BIND
if [ "$HOST_BIND" = "auto" ]; then HOST_BIND="$(_tailnet_ip)"; fi
: "${HOST_BIND:=127.0.0.1}"                                   # last-resort loopback so we never fail-open

# heartbeat node = first roster node unless pinned — FLEET_CONFIG passed as ARGV, never string-interpolated
HEARTBEAT_NODE="${HEARTBEAT_NODE:-$(python3 -c 'import json,sys
try:
    print((json.load(open(sys.argv[1])).get("nodes") or [{}])[0].get("name",""))
except Exception:
    pass' "$FLEET_CONFIG" 2>/dev/null || true)}"

# input validation — values are operator-supplied and get interpolated into rendered scripts, plists, and
# launchctl/systemctl args; reject anything that could break out (argument/shell injection, path traversal)
_num(){ case "${1:-}" in ''|*[!0-9]*) return 1;; esac; }
_id(){  case "${1:-}" in ''|*[!A-Za-z0-9._-]*) return 1;; esac; }
_ip(){  case "${1:-}" in ''|*[!0-9a-fA-F:.]*) return 1;; esac; }
_path(){ case "${1:-}" in *[!A-Za-z0-9._/\ -]*) return 1;; esac; }        # abs/relative path; no ~, no ; | & $ ` ( ) < > " '
_num  "$PORT"            || { echo "fleetmon_deploy: PORT must be an integer" >&2; exit 2; }
_num  "$MIRROR_INTERVAL" || { echo "fleetmon_deploy: MIRROR_INTERVAL must be an integer" >&2; exit 2; }
_id   "$LABEL"           || { echo "fleetmon_deploy: LABEL must match [A-Za-z0-9._-]" >&2; exit 2; }
_ip   "$HOST_BIND"       || { echo "fleetmon_deploy: HOST_BIND is not an IP literal" >&2; exit 2; }
[ -z "$HEARTBEAT_NODE" ] || _id "$HEARTBEAT_NODE" || { echo "fleetmon_deploy: HEARTBEAT_NODE unsafe" >&2; exit 2; }
for p in "$CYBERWARE_ROOT" "$FLEET_CONFIG" "$MIRROR_DIR" "$FLEET_HOME" "$LOG_DIR" "$PYTHON"; do
  _path "$p" || { echo "fleetmon_deploy: shell metachar in a path var — refusing" >&2; exit 2; }
done

mkdir -p "$FLEET_HOME" "$LOG_DIR"
LAUNCHER="$FLEET_HOME/fleetdash.sh"
WATCHDOG="$FLEET_HOME/fleetdash-watchdog.sh"
# fleetdash writes the per-node mirror dir via _safe (non [A-Za-z0-9_-] -> _); sanitize the heartbeat node the
# same way so the watchdog's mark path matches the real dir even for a node name with a dot/etc.
HB_SAFE="$(printf '%s' "${HEARTBEAT_NODE:-}" | tr -c 'A-Za-z0-9_-' '_')"

# non-loopback bind has no app-auth -> require the explicit operator ack the dashboard itself enforces
OPEN_ACK=""
case "$HOST_BIND" in 127.0.0.1|::1|localhost) : ;; *) OPEN_ACK="FLEETDASH_ALLOW_OPEN=1" ;; esac

# ---- render the launcher (resolved values baked in; idempotent; clears a stale listener) -------------------
cat > "$LAUNCHER" <<LSH
#!/usr/bin/env bash
# fleetdash launcher — rendered by cws-fleetmonitor:deploy. Serves the mirrored fleet view; supervised.
set -euo pipefail
for pid in \$(lsof -nP -iTCP:${PORT} -sTCP:LISTEN -t 2>/dev/null); do kill "\$pid" 2>/dev/null || true; done
sleep 1
cd "${CYBERWARE_ROOT}"
exec env ${OPEN_ACK} "${PYTHON}" -m infra.tool.fleetdash \\
  --config "${FLEET_CONFIG}" --serve "${PORT}" --bind "${HOST_BIND}" \\
  --mirror-dir "${MIRROR_DIR}" --mirror-interval "${MIRROR_INTERVAL}"
LSH
chmod +x "$LAUNCHER"

# ---- render the freeze-watchdog (heartbeat = the mirror mtime; kick if wedged) -----------------------------
cat > "$WATCHDOG" <<WSH
#!/usr/bin/env bash
# fleetdash freeze-watchdog — rendered by cws-fleetmonitor:deploy. KeepAlive/systemd Restart can't catch a
# loop that wedges while the process stays alive; the durable mirror stops advancing, so kick the service.
set -euo pipefail
MARK="${MIRROR_DIR}/${HB_SAFE}/index.json"
[ -f "\$MARK" ] || exit 0
mt=\$(stat -c %Y "\$MARK" 2>/dev/null || stat -f %m "\$MARK" 2>/dev/null)
age=\$(( \$(date +%s) - \${mt:-0} ))
if [ "\$age" -gt \$(( ${MIRROR_INTERVAL} * 6 + 30 )) ]; then
  echo "\$(date -u +%FT%TZ) fleetdash mirror stale \${age}s -> restart" >> "${LOG_DIR}/fleetdash.watchdog.log"
  if command -v launchctl >/dev/null 2>&1; then launchctl kickstart -k "gui/\$(id -u)/${LABEL}" 2>/dev/null || true;
  else systemctl --user restart "${LABEL}.service" 2>/dev/null || true; fi
fi
WSH
chmod +x "$WATCHDOG"

# ---- OS-detected supervision -------------------------------------------------------------------------------
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  LA="$HOME/Library/LaunchAgents"; mkdir -p "$LA"; U="$(id -u)"
  for suffix in "" "-watchdog"; do
    lbl="${LABEL}${suffix}"; plist="$LA/${lbl}.plist"
    if [ -z "$suffix" ]; then
      cat > "$plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>${lbl}</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>${LAUNCHER}</string></array>
  <key>WorkingDirectory</key><string>${CYBERWARE_ROOT}</string>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/><key>ThrottleInterval</key><integer>10</integer>
  <key>StandardOutPath</key><string>${LOG_DIR}/fleetdash.out.log</string>
  <key>StandardErrorPath</key><string>${LOG_DIR}/fleetdash.err.log</string>
</dict></plist>
PL
    else
      cat > "$plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>${lbl}</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>${WATCHDOG}</string></array>
  <key>StartInterval</key><integer>60</integer><key>RunAtLoad</key><true/>
  <key>StandardErrorPath</key><string>${LOG_DIR}/fleetdash.watchdog.log</string>
</dict></plist>
PL
    fi
    launchctl bootout   "gui/$U/$lbl" 2>/dev/null || true
    launchctl bootstrap "gui/$U" "$plist" 2>/dev/null || launchctl load -w "$plist" 2>/dev/null || true
  done
  SUPERVISOR="launchd"
elif [ "$OS" = "Linux" ]; then
  UD="$HOME/.config/systemd/user"; mkdir -p "$UD"
  cat > "$UD/${LABEL}.service" <<SVC
[Unit]
Description=cyberware fleet-monitor dashboard
[Service]
ExecStart=/bin/bash ${LAUNCHER}
Restart=always
RestartSec=10
[Install]
WantedBy=default.target
SVC
  cat > "$UD/${LABEL}-watchdog.service" <<SVC
[Unit]
Description=cyberware fleet-monitor freeze watchdog
[Service]
Type=oneshot
ExecStart=/bin/bash ${WATCHDOG}
SVC
  cat > "$UD/${LABEL}-watchdog.timer" <<TMR
[Unit]
Description=run the fleetdash watchdog every 60s
[Timer]
OnBootSec=60
OnUnitActiveSec=60
[Install]
WantedBy=timers.target
TMR
  # enable-linger so the --user manager (and thus the dashboard) starts at BOOT, not only on interactive login
  loginctl enable-linger "$(id -un)" 2>/dev/null || echo "  (enable-linger failed — reboot-survival needs: sudo loginctl enable-linger $(id -un))" >&2
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable --now "${LABEL}.service" "${LABEL}-watchdog.timer" 2>/dev/null || true
  SUPERVISOR="systemd"
else
  echo "fleetmon_deploy: unsupported OS '$OS' (need Darwin/launchd or Linux/systemd)" >&2; exit 3
fi

# ---- value-free deploy record ------------------------------------------------------------------------------
mkdir -p "$REC"
python3 -c "import json,sys;
json.dump({'ok':True,'ts':sys.argv[1],'supervisor':sys.argv[2],'label':sys.argv[3],'port':int(sys.argv[4]),
'bind':sys.argv[5],'mirror_interval':int(sys.argv[6]),'heartbeat_node':sys.argv[7],'launcher':sys.argv[8]},
open(sys.argv[9],'w'), indent=1)" \
  "$(_ts)" "$SUPERVISOR" "$LABEL" "$PORT" "$HOST_BIND" "$MIRROR_INTERVAL" "${HEARTBEAT_NODE:-?}" "$LAUNCHER" \
  "$REC/deploy.json"
echo "fleetmon_deploy: $SUPERVISOR up — $LABEL on ${HOST_BIND}:${PORT} (interval ${MIRROR_INTERVAL}s, heartbeat=${HEARTBEAT_NODE:-?})"
