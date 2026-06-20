#!/usr/bin/env bash
# subscribe_list — localized from NVIDIA/skills vss-manage-alerts (Apache-2.0). Structured-JSON audit line.
# Lists active realtime alert rules from Alert Bridge (GET http://<HOST_IP>:9080/api/v1/realtime) — Workflow D /
# references/alert-subscriptions.md. Optional ALERT_TYPE query filter. Always creates its output file and emits
# one JSON line on stdout, even when Alert Bridge is unreachable or curl is missing (graceful degradation).
# Read-only: an empty rule list is a valid success.
set -uo pipefail
: "${HOST_IP:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/subscribe_list.json"
LOG="${RECORD_STORE%/}/subscribe_list.log"
: > "$OUT"

ALERT_TYPE="${ALERT_TYPE:-}"
BASE_URL="${ALERT_BRIDGE_URL:-http://${HOST_IP}:9080}"

status="ok"
http_code="000"
rule_count="unknown"
if command -v curl >/dev/null 2>&1; then
  result="$(bash "${HERE}/subscribe_list.impl.sh" "$BASE_URL" "$ALERT_TYPE" 2>>"$LOG")" || status="list_failed"
  printf '%s\n' "$result" >> "$LOG"
  http_code="$(printf '%s\n' "$result" | sed -n 's/^http_code=//p' | head -1)"; [ -n "$http_code" ] || http_code="000"
  rule_count="$(printf '%s\n' "$result" | sed -n 's/^rule_count=//p' | head -1)"; [ -n "$rule_count" ] || rule_count="unknown"
else
  status="curl_missing"
fi

printf '{"tool":"subscribe_list","status":"%s","base_url":"%s","alert_type":"%s","http_code":"%s","rule_count":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$BASE_URL" "${ALERT_TYPE:-<all>}" "$http_code" "$rule_count" "$LOG" "$OUT" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
