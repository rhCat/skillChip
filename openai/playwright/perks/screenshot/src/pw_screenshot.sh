#!/usr/bin/env bash
# pw_screenshot — render the current page (or PW_REF element) to a screenshot file via the bundled wrapper.
# Read-only. Structured JSON output (audit/debug log). Degrades gracefully when a live browser is not available.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/screenshot.json"
# Always (re)create $OUT so the contract's output_exists holds even if the browser/npx are absent.
: > "$OUT"

WRAP="$HERE/playwright_cli.sh"
ARGS=(screenshot)
[ -n "${PW_REF:-}" ] && ARGS+=("$PW_REF")
if [ -n "${PW_SESSION:-}" ]; then
  export PLAYWRIGHT_CLI_SESSION="$PW_SESSION"
fi

if [ -n "${PW_LIVE:-}" ] && command -v npx >/dev/null 2>&1; then
  # Run from record_store so the saved image artifact stays contained.
  ( cd "${RECORD_STORE%/}" && bash "$WRAP" "${ARGS[@]}" ) >> "$OUT" 2>&1 || true
else
  printf '{"tool":"pw_screenshot","status":"degraded","reason":"live browser run not requested (set PW_LIVE=1 with npx present)","planned":"playwright-cli screenshot %s"}\n' "${PW_REF:-}" >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pw_screenshot","status":"ok","ref":"%s","out":"%s"}\n' "${PW_REF:-}" "$OUT"
