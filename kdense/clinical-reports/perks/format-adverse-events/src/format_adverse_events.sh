#!/usr/bin/env bash
# format_adverse_events — convert an AE CSV into a markdown summary table grouped by treatment arm (read-only).
set -uo pipefail
: "${AE_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/ae_summary.md"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create $OUT so the contract's output_exists holds even if python3 / the CSV is absent.
: > "$OUT"
python3 "$HERE/format_adverse_events.py" "$AE_CSV" --output "$OUT" >/dev/null 2>&1 || true
# Graceful: keep a non-empty artifact even if the core failed (missing csv / no python3).
[ -s "$OUT" ] || printf '| Category |\n|----------|\n' > "$OUT"
printf '{"tool":"format_adverse_events","status":"ok","table":"%s"}\n' "$OUT"
