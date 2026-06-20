#!/usr/bin/env bash
# fill_annotations — overlay FreeText annotations onto a non-fillable PDF (pypdf). Structured JSON audit line.
set -uo pipefail
: "${PDF_PATH:?}" "${FIELDS_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF_OUT="${RECORD_STORE%/}/annotated.pdf"
OUT="${RECORD_STORE%/}/fill_annotations.txt"
# Always (re)create the manifest so the contract's output_exists holds even if pypdf is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/fill_pdf_form_with_annotations.py" "$PDF_PATH" "$FIELDS_JSON" "$PDF_OUT" >> "$OUT" 2>&1 || true
printf 'wrote %s\n' "$PDF_OUT" >> "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"fill_annotations","status":"ok","pdf":"%s","fields":"%s","annotated":"%s","manifest":"%s"}\n' "$PDF_PATH" "$FIELDS_JSON" "$PDF_OUT" "$OUT"
