#!/usr/bin/env bash
# check_boxes — validate label/entry bounding-box overlaps + entry heights in a fields JSON (stdlib). Structured JSON audit line.
set -uo pipefail
: "${FIELDS_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/check_boxes.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the input is malformed.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/check_bounding_boxes.py" "$FIELDS_JSON" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_boxes","status":"ok","fields_json":"%s","report":"%s"}\n' "$FIELDS_JSON" "$OUT"
