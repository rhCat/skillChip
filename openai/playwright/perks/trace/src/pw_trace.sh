#!/usr/bin/env bash
# pw_trace — record a Playwright trace: tracing-start then tracing-stop via the bundled wrapper (read-only).
# Two chained sub-steps. Structured JSON output (audit/debug log). Degrades gracefully when no live browser.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/trace.json"
# Always (re)create $OUT so the contract's output_exists holds even if the browser/npx are absent.
: > "$OUT"

WRAP="$HERE/playwright_cli.sh"
if [ -n "${PW_SESSION:-}" ]; then
  export PLAYWRIGHT_CLI_SESSION="$PW_SESSION"
fi

if [ -n "${PW_LIVE:-}" ] && command -v npx >/dev/null 2>&1; then
  # Run from record_store so the saved trace artifact stays contained. Chained sub-steps: start then stop.
  ( cd "${RECORD_STORE%/}" && bash "$WRAP" tracing-start && bash "$WRAP" tracing-stop ) >> "$OUT" 2>&1 || true
else
  printf '{"tool":"pw_trace","status":"degraded","reason":"live browser run not requested (set PW_LIVE=1 with npx present)","planned":["playwright-cli tracing-start","playwright-cli tracing-stop"]}\n' >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pw_trace","status":"ok","out":"%s"}\n' "$OUT"
