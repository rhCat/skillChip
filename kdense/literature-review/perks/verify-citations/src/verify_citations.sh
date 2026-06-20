#!/usr/bin/env bash
# verify_citations — extract DOIs from a review markdown, resolve via doi.org + CrossRef, emit a JSON report. Structured JSON output.
set -uo pipefail
: "${REVIEW_MD:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/citation_report.json"
# Always (re)create $OUT so the contract's output_exists holds even if requests/network/python3 is absent or errors.
: > "$OUT"

# The core writes its report next to a *.md input. Stage a copy of the review inside RECORD_STORE so the
# report lands under our control, then normalise its name to citation_report.json.
STAGE="${RECORD_STORE%/}/_review_for_citations.md"
if command -v python3 >/dev/null 2>&1 && [ -f "$REVIEW_MD" ]; then
  cp "$REVIEW_MD" "$STAGE" 2>/dev/null || true
  python3 "$HERE/verify_citations.py" "$STAGE" >>"$OUT.log" 2>&1 || true
  REPORT="${RECORD_STORE%/}/_review_for_citations_citation_report.json"
  [ -s "$REPORT" ] && cp "$REPORT" "$OUT" 2>/dev/null || true
elif ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT.log"
else
  printf 'review markdown not found: %s\n' "$REVIEW_MD" >> "$OUT.log"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"verify_citations","status":"ok","report":"%s"}\n' "$OUT"
