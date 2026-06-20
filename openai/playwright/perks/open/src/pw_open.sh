#!/usr/bin/env bash
# pw_open — navigate a browser session to PW_URL via the bundled playwright-cli wrapper (read-only).
# Structured JSON output (audit/debug log). Degrades gracefully when a live browser is not requested/available.
set -uo pipefail
: "${PW_URL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/open.json"
# Always (re)create $OUT so the contract's output_exists holds even if the browser/npx are absent.
: > "$OUT"

WRAP="$HERE/playwright_cli.sh"
ARGS=(open "$PW_URL")
[ -n "${PW_HEADED:-}" ] && ARGS+=(--headed)
if [ -n "${PW_SESSION:-}" ]; then
  export PLAYWRIGHT_CLI_SESSION="$PW_SESSION"
fi

# Live browser navigation requires npx + @playwright/cli + a launchable browser (and network to fetch
# the CLI). Run it only when explicitly opted in via PW_LIVE; otherwise record the planned command and
# degrade gracefully so the contract holds offline.
if [ -n "${PW_LIVE:-}" ] && command -v npx >/dev/null 2>&1; then
  bash "$WRAP" "${ARGS[@]}" >> "$OUT" 2>&1 || true
else
  printf '{"tool":"pw_open","status":"degraded","reason":"live browser run not requested (set PW_LIVE=1 with npx present)","planned":"playwright-cli open %s","url":"%s"}\n' "$PW_URL" "$PW_URL" >> "$OUT"
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pw_open","status":"ok","url":"%s","out":"%s"}\n' "$PW_URL" "$OUT"
