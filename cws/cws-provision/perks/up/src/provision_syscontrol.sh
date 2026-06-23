#!/usr/bin/env bash
# provision_syscontrol — the always-on system control: enable the fleet services on boot (docker, tailscaled,
# cyberware-govd) and, if AGENT_EXEC is given, install a cyberware-agent systemd unit (Restart=always) so the
# brain loop survives a crash AND a reboot. Governed-clean: systemctl/tee only, NO `sudo`, NO pipe-to-shell.
# DRY_RUN=1 plans only. The FINAL step of `up` — writes the perk's contract output (provision_syscontrol.json).
set -uo pipefail
: "${RECORD_STORE:?}"
DRY="${DRY_RUN:-0}"
ENABLE_SERVICES="${ENABLE_SERVICES:-docker tailscaled cyberware-govd}"
AGENT_EXEC="${AGENT_EXEC:-}"
AGENT_USER="${AGENT_USER:-cyberware}"
OUT="${RECORD_STORE%/}/provision_syscontrol.json"
LOG="${RECORD_STORE%/}/provision_syscontrol.log"; : > "$LOG"
AGENT_UNIT_PATH="/etc/systemd/system/cyberware-agent.service"

do_step() { echo "+ $*" >> "$LOG"; if [ "$DRY" = "1" ]; then return 0; fi; "$@" >> "$LOG" 2>&1; }
status="ok"; agent_unit="false"

# 1. the agent (brain) unit — Restart=always + boot-enabled — only when a run command is supplied
if [ -n "$AGENT_EXEC" ]; then
  unit=$(printf '[Unit]\nDescription=cyberware brain (agent/cortex loop)\nAfter=network-online.target tailscaled.service\nWants=network-online.target\n[Service]\nUser=%s\nEnvironmentFile=-/etc/cyberware/agent.env\nExecStart=%s\nRestart=always\nRestartSec=5\n[Install]\nWantedBy=multi-user.target\n' "$AGENT_USER" "$AGENT_EXEC")
  if [ "$DRY" = "1" ]; then
    { echo "write $AGENT_UNIT_PATH:"; printf '%s\n' "$unit"; } >> "$LOG"
  else
    if printf '%s\n' "$unit" | tee "$AGENT_UNIT_PATH" > /dev/null 2>>"$LOG"; then agent_unit="true"; else status="error"; fi
  fi
  ENABLE_SERVICES="$ENABLE_SERVICES cyberware-agent"
fi

# 2. enable everything on boot (always-on) + reload units
do_step systemctl daemon-reload || true
enabled=""
for svc in $ENABLE_SERVICES; do
  if [ "$DRY" = "1" ]; then
    echo "systemctl enable --now $svc" >> "$LOG"; enabled="$enabled $svc"
  else
    systemctl enable --now "$svc" >> "$LOG" 2>&1 && enabled="$enabled $svc" || echo "  (skip $svc: not installed yet)" >> "$LOG"
  fi
done

[ "$DRY" = "1" ] && status="dry-run"
printf '{"tool":"provision_syscontrol","status":"%s","dry_run":%s,"agent_unit":%s,"enabled":"%s"}\n' \
  "$status" "$([ "$DRY" = "1" ] && echo true || echo false)" "$agent_unit" "$(echo $enabled | sed 's/^ *//')" | tee "$OUT"
[ "$status" = "error" ] && exit 1 || exit 0
