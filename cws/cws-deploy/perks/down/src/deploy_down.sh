#!/usr/bin/env bash
# deploy_down — stop + remove the deployed govd container (the data volume is preserved). Structured JSON output.
set -uo pipefail
: "${RECORD_STORE:?}"
NAME="${NAME:-cyberware}"
OUT="${RECORD_STORE%/}/down.json"
LOG="${RECORD_STORE%/}/down.log"

docker stop "$NAME" > "$LOG" 2>&1 || true
docker rm "$NAME" >> "$LOG" 2>&1 || true
GONE=yes; docker inspect "$NAME" >/dev/null 2>&1 && GONE=no

printf '{"tool":"deploy_down","status":"%s","container":"%s","removed":"%s","note":"data volume preserved","log":"%s"}\n' \
  "$([ "$GONE" = yes ] && echo ok || echo fail)" "$NAME" "$GONE" "$LOG" | tee "$OUT"
[ "$GONE" = yes ]
