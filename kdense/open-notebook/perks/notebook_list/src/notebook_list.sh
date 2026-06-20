#!/usr/bin/env bash
# notebook_list — GET /api/notebooks (list notebooks). Read-only. Structured JSON output (audit/debug log).
set -uo pipefail
: "${OPEN_NOTEBOOK_URL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/notebooks.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  OPEN_NOTEBOOK_URL="$OPEN_NOTEBOOK_URL" \
  NB_ARCHIVED="${NB_ARCHIVED:-false}" \
  python3 "$HERE/notebook_list_core.py" "$OUT" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"notebook_list","status":"ok","notebooks":"%s"}\n' "$OUT"
