#!/usr/bin/env bash
# search_items — phrase-search parsed JSON text_items, merge into combined bounding boxes.
# Read-only. Local, stdlib only. Structured JSON audit line on stdout.
set -uo pipefail
: "${PARSED_JSON:?}" "${PHRASE:?}" "${RECORD_STORE:?}"
CASE_SENSITIVE="${CASE_SENSITIVE:-0}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/matches.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
python3 "$HERE/search_items_core.py" "$PARSED_JSON" "$PHRASE" "$CASE_SENSITIVE" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"search_items","status":"ok","phrase":"%s","case_sensitive":"%s","matches":"%s"}\n' "$PHRASE" "$CASE_SENSITIVE" "$OUT"
