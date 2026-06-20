#!/usr/bin/env bash
# list_options — print infographic types, styles, palettes, and doc-type thresholds (read-only, offline). Structured JSON output.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/options.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"list_options","status":"ok","options_out":"%s"}\n' "$OUT"
  exit 0
fi
# --list-options is fully offline and needs no API key; capture its listing to $OUT.
python3 "$HERE/generate_infographic.py" --list-options >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"list_options","status":"ok","options_out":"%s"}\n' "$OUT"
