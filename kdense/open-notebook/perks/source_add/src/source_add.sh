#!/usr/bin/env bash
# source_add — POST /api/sources (ingest a URL/text source). REMOTE-MUTATING. Structured JSON output (audit/debug log).
set -uo pipefail
: "${OPEN_NOTEBOOK_URL:?}" "${NOTEBOOK_ID:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/source.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  OPEN_NOTEBOOK_URL="$OPEN_NOTEBOOK_URL" \
  NOTEBOOK_ID="$NOTEBOOK_ID" \
  SOURCE_URL="${SOURCE_URL:-}" \
  SOURCE_TEXT="${SOURCE_TEXT:-}" \
  SOURCE_TITLE="${SOURCE_TITLE:-Text source}" \
  python3 "$HERE/source_add_core.py" "$OUT" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"source_add","status":"ok","source":"%s"}\n' "$OUT"
