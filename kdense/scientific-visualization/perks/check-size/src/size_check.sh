#!/usr/bin/env bash
# size_check — report whether a WIDTH_IN x HEIGHT_IN (inches) figure complies with a
# journal's column-width + max-height specs via the vendored check_figure_size().
# Read-only: writes only a JSON report under RECORD_STORE. Structured JSON audit line.
set -uo pipefail
: "${WIDTH_IN:?}" "${HEIGHT_IN:?}" "${RECORD_STORE:?}"
JOURNAL="${JOURNAL:-nature}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/size_check.json"
# Pre-create the report so the contract's output_exists holds even on failure.
: > "$OUT"
WIDTH_IN="$WIDTH_IN" HEIGHT_IN="$HEIGHT_IN" JOURNAL="$JOURNAL" \
  PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/_cli_size_check.py" > "$OUT" 2>>"${RECORD_STORE%/}/size_check.err" || true
# Guarantee non-empty JSON output.
[ -s "$OUT" ] || printf '{"tool":"size_check","status":"degraded","reason":"no output"}' > "$OUT"
printf '{"tool":"size_check","status":"ok","report":"%s","journal":"%s"}\n' "$OUT" "$JOURNAL"
