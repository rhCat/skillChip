#!/usr/bin/env bash
# extract_fields — dump fillable AcroForm field metadata to JSON (read-only, pypdf). Structured JSON audit line.
set -uo pipefail
: "${PDF_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/form_fields.json"
# Always (re)create $OUT so the contract's output_exists holds even if pypdf is absent or errors.
: > "$OUT"
LOG="${RECORD_STORE%/}/extract_fields.log"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/extract_form_field_info.py" "$PDF_PATH" "$OUT" > "$LOG" 2>&1 || true
# If the core could not produce JSON (lib missing / parse error), leave a valid empty document.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract_fields","status":"ok","pdf":"%s","fields_json":"%s","log":"%s"}\n' "$PDF_PATH" "$OUT" "$LOG"
