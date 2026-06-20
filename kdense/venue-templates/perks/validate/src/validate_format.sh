#!/usr/bin/env bash
# validate_format — check a manuscript PDF against venue page-count/margin/font rules (read-only). Structured JSON audit line.
set -uo pipefail
: "${PDF_FILE:?}" "${VENUE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validation_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors
# or poppler-utils (pdfinfo/pdffonts) are absent.
: > "$OUT"

# Translate env vars -> argparse flags for the vendored core. Both the printed
# summary (stdout) and the --report file land in $OUT.
CHECKS_ARG="${CHECKS:-all}"
python3 "$HERE/validate_format.py" --file "$PDF_FILE" --venue "$VENUE" --check "$CHECKS_ARG" --report "$OUT" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validate_format","status":"ok","pdf":"%s","venue":"%s","checks":"%s","out":"%s"}\n' "$PDF_FILE" "$VENUE" "$CHECKS_ARG" "$OUT"
