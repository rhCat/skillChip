#!/usr/bin/env bash
# generate_pdf — render a markdown literature review to PDF via pandoc/xelatex. Structured JSON output.
set -uo pipefail
: "${REVIEW_MD:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/run.log"
PDF="${RECORD_STORE%/}/review.pdf"
# Always (re)create $LOG so the contract's output_exists holds even if pandoc/python3 is absent or errors.
: > "$LOG"

STYLE="${CITATION_STYLE:-apa}"
ARGS=("$HERE/generate_pdf.py" "$REVIEW_MD" "$PDF" "--citation-style" "$STYLE")
[ "${TOC:-1}" = "0" ] && ARGS+=("--no-toc")
[ "${NUMBER_SECTIONS:-1}" = "0" ] && ARGS+=("--no-numbers")

if command -v python3 >/dev/null 2>&1 && [ -f "$REVIEW_MD" ]; then
  python3 "${ARGS[@]}" >>"$LOG" 2>&1 || true
elif ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$LOG"
else
  printf 'review markdown not found: %s\n' "$REVIEW_MD" >> "$LOG"
fi

[ -s "$LOG" ] || printf '{}' > "$LOG"
PDF_OK=false; [ -s "$PDF" ] && PDF_OK=true
printf '{"tool":"generate_pdf","status":"ok","pdf":"%s","pdf_produced":%s,"log":"%s"}\n' "$PDF" "$PDF_OK" "$LOG"
