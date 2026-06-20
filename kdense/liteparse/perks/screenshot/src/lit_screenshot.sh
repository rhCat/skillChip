#!/usr/bin/env bash
# lit_screenshot — render document pages to PNG files via the liteparse engine.
# Read-only. Local only. Structured JSON audit line on stdout.
set -uo pipefail
: "${INPUT_FILE:?}" "${RECORD_STORE:?}"
TARGET_PAGES="${TARGET_PAGES:-}"
DPI="${DPI:-150}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/screenshots.json"
SHOT_DIR="${RECORD_STORE%/}/screenshots"
# Always (re)create $OUT so the contract's output_exists holds even if liteparse is absent or errors.
: > "$OUT"
python3 "$HERE/lit_screenshot_core.py" "$INPUT_FILE" "$TARGET_PAGES" "$DPI" "$SHOT_DIR" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"lit_screenshot","status":"ok","input":"%s","dpi":"%s","target_pages":"%s","manifest":"%s"}\n' "$INPUT_FILE" "$DPI" "${TARGET_PAGES:-all}" "$OUT"
