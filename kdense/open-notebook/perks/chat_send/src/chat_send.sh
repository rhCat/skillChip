#!/usr/bin/env bash
# chat_send — POST /api/chat/execute (send a message with context). REMOTE-MUTATING. Structured JSON output (audit/debug log).
set -uo pipefail
: "${OPEN_NOTEBOOK_URL:?}" "${SESSION_ID:?}" "${CHAT_MESSAGE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/chat_response.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  OPEN_NOTEBOOK_URL="$OPEN_NOTEBOOK_URL" \
  SESSION_ID="$SESSION_ID" \
  CHAT_MESSAGE="$CHAT_MESSAGE" \
  INCLUDE_SOURCES="${INCLUDE_SOURCES:-true}" \
  INCLUDE_NOTES="${INCLUDE_NOTES:-true}" \
  MODEL_OVERRIDE="${MODEL_OVERRIDE:-}" \
  python3 "$HERE/chat_send_core.py" "$OUT" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"chat_send","status":"ok","chat_response":"%s"}\n' "$OUT"
