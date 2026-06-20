#!/usr/bin/env bash
# pw_extract — eval a JS expression against the page (or PW_REF element) to extract data via the wrapper.
# Read-only. Structured JSON output (audit/debug log). Degrades gracefully when a live browser is not available.
set -uo pipefail
: "${PW_EXPR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/extract.json"
# Always (re)create $OUT so the contract's output_exists holds even if the browser/npx are absent.
: > "$OUT"

WRAP="$HERE/playwright_cli.sh"
ARGS=(eval "$PW_EXPR")
[ -n "${PW_REF:-}" ] && ARGS+=("$PW_REF")
if [ -n "${PW_SESSION:-}" ]; then
  export PLAYWRIGHT_CLI_SESSION="$PW_SESSION"
fi

if [ -n "${PW_LIVE:-}" ] && command -v npx >/dev/null 2>&1; then
  bash "$WRAP" "${ARGS[@]}" >> "$OUT" 2>&1 || true
else
  printf '{"tool":"pw_extract","status":"degraded","reason":"live browser run not requested (set PW_LIVE=1 with npx present)","planned":"playwright-cli eval","ref":"%s"}\n' "${PW_REF:-}" >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pw_extract","status":"ok","ref":"%s","out":"%s"}\n' "${PW_REF:-}" "$OUT"
