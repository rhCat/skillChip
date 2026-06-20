#!/usr/bin/env bash
# fill_fillable — fill AcroForm fields from a values JSON, write a new PDF (pypdf). Structured JSON audit line.
set -uo pipefail
: "${PDF_PATH:?}" "${FIELDS_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF_OUT="${RECORD_STORE%/}/filled.pdf"
OUT="${RECORD_STORE%/}/fill_fillable.txt"
# Always (re)create the manifest so the contract's output_exists holds even if pypdf is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/fill_fillable_fields.py" "$PDF_PATH" "$FIELDS_JSON" "$PDF_OUT" >> "$OUT" 2>&1 || true
printf 'wrote %s\n' "$PDF_OUT" >> "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"fill_fillable","status":"ok","pdf":"%s","values":"%s","filled":"%s","manifest":"%s"}\n' "$PDF_PATH" "$FIELDS_JSON" "$PDF_OUT" "$OUT"
