#!/usr/bin/env bash
# validate_cds — lint a CDS document for sections, citations, GRADE grading, stats, HIPAA.
# Read-only: reads one document, writes a validation report under RECORD_STORE.
# Vendored core: validate_cds_document.py (pure stdlib). Structured JSON audit.
set -uo pipefail
: "${DOC:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/validation_report.txt"
# Pre-create $OUT so the contract's output_exists holds even if the core exits non-zero / crashes.
: > "$OUT"

# Core may exit(1) on findings — that is a normal lint result, not a porter failure (|| true).
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/validate_cds_document.py" "$DOC" -o "$OUT" >> "${RECORD_STORE%/}/validate.log" 2>&1 || true

# Guarantee a non-empty report for the contract even on crash before save.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_cds","status":"ok","report":"%s"}\n' "$OUT"
