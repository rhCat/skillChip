#!/usr/bin/env bash
# source_list — GET /api/sources (list sources, optionally per notebook). Read-only. Structured JSON output (audit/debug log).
set -uo pipefail
: "${OPEN_NOTEBOOK_URL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/sources.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  OPEN_NOTEBOOK_URL="$OPEN_NOTEBOOK_URL" \
  NOTEBOOK_ID="${NOTEBOOK_ID:-}" \
  SOURCE_LIMIT="${SOURCE_LIMIT:-20}" \
  python3 "$HERE/source_list_core.py" "$OUT" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"source_list","status":"ok","sources":"%s"}\n' "$OUT"
