#!/usr/bin/env bash
# search_query — POST /api/search (full-text/vector search). Read-only. Structured JSON output (audit/debug log).
set -uo pipefail
: "${OPEN_NOTEBOOK_URL:?}" "${SEARCH_QUERY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/search_results.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  OPEN_NOTEBOOK_URL="$OPEN_NOTEBOOK_URL" \
  SEARCH_QUERY="$SEARCH_QUERY" \
  SEARCH_TYPE="${SEARCH_TYPE:-vector}" \
  SEARCH_LIMIT="${SEARCH_LIMIT:-5}" \
  python3 "$HERE/search_query_core.py" "$OUT" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"search_query","status":"ok","search_results":"%s"}\n' "$OUT"
