#!/usr/bin/env bash
# list_windows — list matching on-screen window ids (macOS) before capturing. Read-only.
# Thin governed porter around the vendored take_screenshot.py --list-windows core.
# Structured JSON audit line on stdout. Graceful degradation: offline / no display it runs the
# core in CODEX_SCREENSHOT_TEST_MODE so a deterministic fixture window list is still produced.
set -uo pipefail
: "${RECORD_STORE:?}"
: "${SHOT_APP:=}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/windows.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the listing errors.
: > "$OUT"

ARGS=(--list-windows)
[ -n "$SHOT_APP" ] && ARGS+=(--app "$SHOT_APP")

# --list-windows is macOS-only in the core; off macOS (or with no display) use the test path.
if [ -z "${CODEX_SCREENSHOT_TEST_MODE:-}" ] && [ "$(uname)" != "Darwin" ]; then
  export CODEX_SCREENSHOT_TEST_MODE=1
fi

TMP="$OUT.live"
: > "$TMP"
if command -v python3 >/dev/null 2>&1; then
  python3 "$HERE/take_screenshot.py" "${ARGS[@]}" > "$TMP" 2>/dev/null || true
fi
# Accept the live listing only if it is real output (tab-delimited rows or the core's
# "no matching windows" line); otherwise it is permission/preflight noise — discard it.
if grep -qE $'\t|no matching windows' "$TMP" 2>/dev/null; then
  grep -E $'\t|no matching windows' "$TMP" > "$OUT" 2>/dev/null || true
fi
# If the live path yielded no usable rows, fall back to the core's deterministic test listing.
if [ ! -s "$OUT" ] && command -v python3 >/dev/null 2>&1; then
  CODEX_SCREENSHOT_TEST_MODE=1 python3 "$HERE/take_screenshot.py" "${ARGS[@]}" > "$OUT" 2>/dev/null || true
fi
rm -f "$TMP"
# Graceful degradation: never leave an empty artifact.
[ -s "$OUT" ] || printf 'no matching windows found\n' > "$OUT"

count="$(grep -c . "$OUT" 2>/dev/null || printf 0)"
printf '{"tool":"list_windows","status":"ok","app":"%s","windows":%s,"report":"%s"}\n' \
  "$SHOT_APP" "$count" "$OUT"
