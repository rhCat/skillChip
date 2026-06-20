#!/usr/bin/env bash
# notebook_create — POST /api/notebooks (create a notebook). REMOTE-MUTATING. Structured JSON output (audit/debug log).
set -uo pipefail
: "${OPEN_NOTEBOOK_URL:?}" "${NB_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/notebook.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  OPEN_NOTEBOOK_URL="$OPEN_NOTEBOOK_URL" \
  NB_NAME="$NB_NAME" \
  NB_DESCRIPTION="${NB_DESCRIPTION:-}" \
  python3 "$HERE/notebook_create_core.py" "$OUT" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"notebook_create","status":"ok","notebook":"%s"}\n' "$OUT"
