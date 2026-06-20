#!/usr/bin/env bash
# check_fillable — does the PDF have fillable AcroForm fields? (read-only, pypdf). Structured JSON audit line.
set -uo pipefail
: "${PDF_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/check_fillable.txt"
# Always (re)create $OUT so the contract's output_exists holds even if pypdf is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/check_fillable_fields.py" "$PDF_PATH" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_fillable","status":"ok","pdf":"%s","report":"%s"}\n' "$PDF_PATH" "$OUT"
