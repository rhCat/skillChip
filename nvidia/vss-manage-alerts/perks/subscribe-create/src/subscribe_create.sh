#!/usr/bin/env bash
# subscribe_create — localized from NVIDIA/skills vss-manage-alerts (Apache-2.0). Structured-JSON audit line.
# Creates a realtime alert rule on Alert Bridge (POST http://<HOST_IP>:9080/api/v1/realtime) — Workflow D /
# references/alert-subscriptions.md. Always creates its output file and emits one JSON line on stdout, even
# when the Alert Bridge endpoint is unreachable or python3/curl is missing (graceful degradation).
set -uo pipefail
: "${HOST_IP:?}" "${LIVE_STREAM_URL:?}" "${ALERT_TYPE:?}" "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/subscribe_create.json"
LOG="${RECORD_STORE%/}/subscribe_create.log"
: > "$OUT"

SENSOR_ID="${SENSOR_ID:-}"
SENSOR_NAME="${SENSOR_NAME:-}"
SYSTEM_PROMPT="${SYSTEM_PROMPT:-Answer yes or no}"
CHUNK_DURATION="${CHUNK_DURATION:-30}"
CHUNK_OVERLAP="${CHUNK_OVERLAP:-5}"
BASE_URL="${ALERT_BRIDGE_URL:-http://${HOST_IP}:9080}"

status="ok"
http_code="000"
if command -v python3 >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
  result="$(bash "${HERE}/subscribe_create.impl.sh" "$BASE_URL" "$LIVE_STREAM_URL" "$ALERT_TYPE" "$PROMPT" \
              "$SENSOR_ID" "$SENSOR_NAME" "$SYSTEM_PROMPT" "$CHUNK_DURATION" "$CHUNK_OVERLAP" 2>>"$LOG")" || status="create_failed"
  printf '%s\n' "$result" >> "$LOG"
  http_code="$(printf '%s\n' "$result" | sed -n 's/^http_code=//p' | head -1)"
  [ -n "$http_code" ] || http_code="000"
else
  status="deps_missing"
fi

printf '{"tool":"subscribe_create","status":"%s","base_url":"%s","alert_type":"%s","http_code":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$BASE_URL" "$ALERT_TYPE" "$http_code" "$LOG" "$OUT" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
