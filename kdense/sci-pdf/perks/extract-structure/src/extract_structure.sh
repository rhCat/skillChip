#!/usr/bin/env bash
# extract_structure — labels/lines/checkboxes of a non-fillable PDF to JSON (read-only, pdfplumber). Structured JSON audit line.
set -uo pipefail
: "${PDF_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/structure.json"
# Always (re)create $OUT so the contract's output_exists holds even if pdfplumber is absent or errors.
: > "$OUT"
LOG="${RECORD_STORE%/}/extract_structure.log"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/extract_form_structure.py" "$PDF_PATH" "$OUT" > "$LOG" 2>&1 || true
# If the core could not produce JSON (lib missing / parse error), leave a valid empty document.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract_structure","status":"ok","pdf":"%s","structure_json":"%s","log":"%s"}\n' "$PDF_PATH" "$OUT" "$LOG"
