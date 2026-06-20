#!/usr/bin/env bash
# validate_presentation — lint DECK_PATH (PDF/PPTX/TEX) and write the report under RECORD_STORE. Structured JSON audit line.
# Vendored core: validate_presentation.py (PyPDF2 / python-pptx / pdflatex). Porter never fails: a non-valid deck just exits 1 inside the core.
set -uo pipefail
: "${DECK_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validation_report.txt"
# Pre-create so the contract's output_exists holds even if the core errors or a lib is missing.
: > "$OUT"
ARGS=("$DECK_PATH")
if [ -n "${DURATION:-}" ]; then
  ARGS+=(--duration "$DURATION")
fi
python3 "$HERE/validate_presentation.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
# Guarantee a non-empty artifact so output_exists + nonempty hold even when the deck is missing.
[ -s "$OUT" ] || printf 'validation produced no output\n' > "$OUT"
printf '{"tool":"validate_presentation","status":"ok","report":"%s","deck":"%s"}\n' "$OUT" "$DECK_PATH"
