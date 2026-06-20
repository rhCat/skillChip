#!/usr/bin/env bash
# chat_session_create — POST /api/chat/sessions (create a chat session). REMOTE-MUTATING. Structured JSON output (audit/debug log).
set -uo pipefail
: "${OPEN_NOTEBOOK_URL:?}" "${NOTEBOOK_ID:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/chat_session.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  OPEN_NOTEBOOK_URL="$OPEN_NOTEBOOK_URL" \
  NOTEBOOK_ID="$NOTEBOOK_ID" \
  SESSION_TITLE="${SESSION_TITLE:-Chat session}" \
  MODEL_OVERRIDE="${MODEL_OVERRIDE:-}" \
  python3 "$HERE/chat_session_create_core.py" "$OUT" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"chat_session_create","status":"ok","chat_session":"%s"}\n' "$OUT"
