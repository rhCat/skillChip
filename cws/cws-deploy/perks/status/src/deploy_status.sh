#!/usr/bin/env bash
# deploy_status — report the deployed govd container + its /health (read-only). Structured JSON output.
set -uo pipefail
: "${RECORD_STORE:?}"
NAME="${NAME:-cyberware}"
PORT="${PORT:-5773}"
OUT="${RECORD_STORE%/}/status.json"
HEALTH_FILE="${RECORD_STORE%/}/health.json"

STATE="$(docker inspect -f '{{.State.Status}}' "$NAME" 2>/dev/null || echo absent)"
HEALTH=down
if curl -fsS -m 5 "http://127.0.0.1:${PORT}/health" -o "$HEALTH_FILE" 2>/dev/null; then HEALTH=ok; fi
CHIP="$(grep -o '"chip_sha"[^,]*' "$HEALTH_FILE" 2>/dev/null | head -1 | sed 's/.*: *"//;s/".*//')"

printf '{"tool":"deploy_status","status":"ok","container":"%s","state":"%s","health":"%s","chip_sha":"%s","report":"%s"}\n' \
  "$NAME" "${STATE:-absent}" "$HEALTH" "${CHIP:-unknown}" "$OUT" | tee "$OUT"
