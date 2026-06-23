#!/usr/bin/env bash
# provision_base — base node prep: apt deps (bwrap/uidmap/age/jq/curl/python3) + a non-login service user +
# the /etc/cyberware config dir. Governed-clean: apt only, NO `sudo` and NO pipe-to-shell — run the WHOLE
# governed executor as root (provisioning needs root; the never-root rule is for the confined exod limb, not
# operator-run provisioning). DRY_RUN=1 plans only. Emits structured JSON to $RECORD_STORE.
set -uo pipefail
: "${RECORD_STORE:?}"
DRY="${DRY_RUN:-0}"
CW_USER="${CW_USER:-cyberware}"
CW_ETC="${CW_ETC:-/etc/cyberware}"
OUT="${RECORD_STORE%/}/provision_base.json"
LOG="${RECORD_STORE%/}/provision_base.log"; : > "$LOG"
DEPS="bubblewrap uidmap age jq curl ca-certificates python3 python3-venv"

do_step() { echo "+ $*" >> "$LOG"; if [ "$DRY" = "1" ]; then return 0; fi; "$@" >> "$LOG" 2>&1; }
status="ok"
if [ "$DRY" = "1" ]; then
  {
    echo "apt-get update -qq"
    echo "apt-get install -y --no-install-recommends $DEPS"
    echo "id $CW_USER || useradd -r -s /usr/sbin/nologin $CW_USER"
    echo "install -d -m 0750 $CW_ETC"
  } >> "$LOG"
  status="dry-run"
else
  do_step apt-get update -qq || status="error"
  do_step apt-get install -y --no-install-recommends $DEPS || status="error"
  id "$CW_USER" >/dev/null 2>&1 || do_step useradd -r -s /usr/sbin/nologin "$CW_USER" || true
  do_step install -d -m 0750 "$CW_ETC" || true
fi

printf '{"tool":"provision_base","status":"%s","dry_run":%s,"user":"%s","etc":"%s","deps":"%s"}\n' \
  "$status" "$([ "$DRY" = "1" ] && echo true || echo false)" "$CW_USER" "$CW_ETC" "$DEPS" | tee "$OUT"
[ "$status" = "error" ] && exit 1 || exit 0
