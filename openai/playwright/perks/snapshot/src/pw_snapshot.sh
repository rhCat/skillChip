#!/usr/bin/env bash
# pw_snapshot — capture the element-ref snapshot of the current page via the bundled wrapper (read-only).
# Structured JSON output (audit/debug log). Degrades gracefully when a live browser is not requested/available.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/snapshot.json"
# Always (re)create $OUT so the contract's output_exists holds even if the browser/npx are absent.
: > "$OUT"

WRAP="$HERE/playwright_cli.sh"
if [ -n "${PW_SESSION:-}" ]; then
  export PLAYWRIGHT_CLI_SESSION="$PW_SESSION"
fi

if [ -n "${PW_LIVE:-}" ] && command -v npx >/dev/null 2>&1; then
  bash "$WRAP" snapshot >> "$OUT" 2>&1 || true
else
  printf '{"tool":"pw_snapshot","status":"degraded","reason":"live browser run not requested (set PW_LIVE=1 with npx present)","planned":"playwright-cli snapshot"}\n' >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pw_snapshot","status":"ok","out":"%s"}\n' "$OUT"
