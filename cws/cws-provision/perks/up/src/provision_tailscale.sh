#!/usr/bin/env bash
# provision_tailscale — install Tailscale from its apt repo (key + list fetched with `curl -o`, NOT piped to a
# shell) and join the tailnet over the private overlay (all outbound, NAT traversal → NO inbound firewall
# change). tailscaled is enabled on boot by the package. Governed-clean: apt only, NO `sudo`, NO pipe-to-shell.
# The auth key is read from TS_AUTHKEY_FILE (a *_FILE pointer) — never a plaintext var, never logged. Use a
# NON-ephemeral key for an always-on node. DRY_RUN=1 plans only.
set -uo pipefail
: "${RECORD_STORE:?}"
DRY="${DRY_RUN:-0}"
TS_HOSTNAME="${TS_HOSTNAME:-cyberware-node}"
TS_AUTHKEY_FILE="${TS_AUTHKEY_FILE:-}"
OUT="${RECORD_STORE%/}/provision_tailscale.json"
LOG="${RECORD_STORE%/}/provision_tailscale.log"; : > "$LOG"
CODENAME="$(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-noble}")"
KEYRING=/usr/share/keyrings/tailscale-archive-keyring.gpg
LIST=/etc/apt/sources.list.d/tailscale.list

do_step() { echo "+ $*" >> "$LOG"; if [ "$DRY" = "1" ]; then return 0; fi; "$@" >> "$LOG" 2>&1; }
have_key="false"; [ -n "$TS_AUTHKEY_FILE" ] && [ -f "$TS_AUTHKEY_FILE" ] && have_key="true"
status="ok"; joined="false"; ip=""

if [ "$DRY" = "1" ]; then
  {
    echo "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg -o $KEYRING"
    echo "curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list -o $LIST"
    echo "apt-get update && apt-get install -y tailscale"
    echo "tailscale up --hostname=$TS_HOSTNAME --authkey=@$TS_AUTHKEY_FILE   # key from the *_FILE pointer"
  } >> "$LOG"
  status="dry-run"
else
  if ! command -v tailscale >/dev/null 2>&1; then
    do_step curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" -o "$KEYRING" || status="error"
    do_step curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.tailscale-keyring.list" -o "$LIST" || status="error"
    do_step apt-get update -qq || status="error"
    do_step apt-get install -y tailscale || status="error"
  fi
  if [ "$status" != "error" ] && [ "$have_key" = "true" ]; then
    if tailscale up --hostname="$TS_HOSTNAME" --authkey="$(cat "$TS_AUTHKEY_FILE")" >> "$LOG" 2>&1; then
      joined="true"
    else
      status="error"
    fi
  fi
  ip="$(tailscale ip -4 2>/dev/null | head -1)"
fi

printf '{"tool":"provision_tailscale","status":"%s","dry_run":%s,"hostname":"%s","has_key":%s,"joined":%s,"overlay_ip":"%s"}\n' \
  "$status" "$([ "$DRY" = "1" ] && echo true || echo false)" "$TS_HOSTNAME" "$have_key" "$joined" "$ip" | tee "$OUT"
[ "$status" = "error" ] && exit 1 || exit 0
