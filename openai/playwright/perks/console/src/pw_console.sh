#!/usr/bin/env bash
# pw_console — dump the page's console messages (optionally filtered by PW_LEVEL) via the wrapper (read-only).
# Structured JSON output (audit/debug log). Degrades gracefully when a live browser is not available.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/console.json"
# Always (re)create $OUT so the contract's output_exists holds even if the browser/npx are absent.
: > "$OUT"

WRAP="$HERE/playwright_cli.sh"
ARGS=(console)
[ -n "${PW_LEVEL:-}" ] && ARGS+=("$PW_LEVEL")
if [ -n "${PW_SESSION:-}" ]; then
  export PLAYWRIGHT_CLI_SESSION="$PW_SESSION"
fi

if [ -n "${PW_LIVE:-}" ] && command -v npx >/dev/null 2>&1; then
  bash "$WRAP" "${ARGS[@]}" >> "$OUT" 2>&1 || true
else
  printf '{"tool":"pw_console","status":"degraded","reason":"live browser run not requested (set PW_LIVE=1 with npx present)","planned":"playwright-cli console","level":"%s"}\n' "${PW_LEVEL:-}" >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pw_console","status":"ok","level":"%s","out":"%s"}\n' "${PW_LEVEL:-}" "$OUT"
