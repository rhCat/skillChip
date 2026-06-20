#!/usr/bin/env bash
# subscribe_stop — localized from NVIDIA/skills vss-manage-alerts (Apache-2.0). Structured-JSON audit line.
# Deletes (stops) a realtime alert rule on Alert Bridge by rule ID
# (DELETE http://<HOST_IP>:9080/api/v1/realtime/<RULE_ID>) — Workflow D / references/alert-subscriptions.md.
# DESTRUCTIVE: the skill's user-facing yes/no confirmation gate must be satisfied by the caller before this runs.
# Always creates its output file and emits one JSON line on stdout, even when Alert Bridge is unreachable or
# curl is missing (graceful degradation).
set -uo pipefail
: "${HOST_IP:?}" "${RULE_ID:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/subscribe_stop.json"
LOG="${RECORD_STORE%/}/subscribe_stop.log"
: > "$OUT"

BASE_URL="${ALERT_BRIDGE_URL:-http://${HOST_IP}:9080}"

status="ok"
http_code="000"
if command -v curl >/dev/null 2>&1; then
  result="$(bash "${HERE}/subscribe_stop.impl.sh" "$BASE_URL" "$RULE_ID" 2>>"$LOG")" || status="stop_failed"
  printf '%s\n' "$result" >> "$LOG"
  http_code="$(printf '%s\n' "$result" | sed -n 's/^http_code=//p' | head -1)"; [ -n "$http_code" ] || http_code="000"
else
  status="curl_missing"
fi

printf '{"tool":"subscribe_stop","status":"%s","base_url":"%s","rule_id":"%s","http_code":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$BASE_URL" "$RULE_ID" "$http_code" "$LOG" "$OUT" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
