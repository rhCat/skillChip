#!/usr/bin/env bash
# provision_docker — install Docker Engine + the compose v2 plugin from the DISTRO apt repo (docker.io +
# docker-compose-v2), add the service user to the docker group, and enable docker on boot. Governed-clean:
# apt only, NO `sudo`, NO pipe-to-shell. Run the governed executor as root. DRY_RUN=1 plans only. Idempotent.
set -uo pipefail
: "${RECORD_STORE:?}"
DRY="${DRY_RUN:-0}"
CW_USER="${CW_USER:-cyberware}"
OUT="${RECORD_STORE%/}/provision_docker.json"
LOG="${RECORD_STORE%/}/provision_docker.log"; : > "$LOG"

do_step() { echo "+ $*" >> "$LOG"; if [ "$DRY" = "1" ]; then return 0; fi; "$@" >> "$LOG" 2>&1; }
status="ok"
if [ "$DRY" = "1" ]; then
  {
    echo "apt-get install -y docker.io docker-compose-v2"
    echo "usermod -aG docker $CW_USER"
    echo "systemctl enable --now docker"
  } >> "$LOG"
  status="dry-run"
elif command -v docker >/dev/null 2>&1; then
  status="present"
  do_step usermod -aG docker "$CW_USER" || true
  do_step systemctl enable --now docker || true
else
  do_step apt-get update -qq || true
  if do_step apt-get install -y docker.io; then
    do_step apt-get install -y docker-compose-v2 || true   # compose plugin: 24.04+; best-effort on older
    do_step usermod -aG docker "$CW_USER" || true
    do_step systemctl enable --now docker || true
    status="installed"
  else
    status="error"
  fi
fi

printf '{"tool":"provision_docker","status":"%s","dry_run":%s,"docker":"%s","compose":"%s"}\n' \
  "$status" "$([ "$DRY" = "1" ] && echo true || echo false)" \
  "$(command -v docker 2>/dev/null || echo none)" \
  "$([ "$DRY" = "1" ] && echo plugin || (docker compose version >/dev/null 2>&1 && echo yes || echo no))" | tee "$OUT"
[ "$status" = "error" ] && exit 1 || exit 0
