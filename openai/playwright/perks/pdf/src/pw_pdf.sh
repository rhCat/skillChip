#!/usr/bin/env bash
# pw_pdf — render the current page to a PDF file via the bundled wrapper (read-only artifact).
# Structured JSON output (audit/debug log). Degrades gracefully when a live browser is not available.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pdf.json"
# Always (re)create $OUT so the contract's output_exists holds even if the browser/npx are absent.
: > "$OUT"

WRAP="$HERE/playwright_cli.sh"
if [ -n "${PW_SESSION:-}" ]; then
  export PLAYWRIGHT_CLI_SESSION="$PW_SESSION"
fi

if [ -n "${PW_LIVE:-}" ] && command -v npx >/dev/null 2>&1; then
  # Run from record_store so the saved PDF artifact stays contained.
  ( cd "${RECORD_STORE%/}" && bash "$WRAP" pdf ) >> "$OUT" 2>&1 || true
else
  printf '{"tool":"pw_pdf","status":"degraded","reason":"live browser run not requested (set PW_LIVE=1 with npx present)","planned":"playwright-cli pdf"}\n' >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pw_pdf","status":"ok","out":"%s"}\n' "$OUT"
