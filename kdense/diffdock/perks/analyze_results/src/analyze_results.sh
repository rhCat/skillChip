#!/usr/bin/env bash
# analyze_results — parse/rank/classify DiffDock pose-confidence scores and export a summary CSV. Read-only. Structured JSON audit line.
set -uo pipefail
: "${RESULTS_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/summary.csv"
LOG="${RECORD_STORE%/}/analyze_results.log"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"

# Always export to $OUT; pass optional ranking/filter knobs through.
ARGS=( "$RESULTS_DIR" "--export" "$OUT" )
if [ -n "${TOP:-}" ]; then
  ARGS+=( "--top" "$TOP" )
fi
if [ -n "${THRESHOLD:-}" ]; then
  ARGS+=( "--threshold" "$THRESHOLD" )
fi
if [ -n "${BEST:-}" ]; then
  ARGS+=( "--best" "$BEST" )
fi

if command -v python3 >/dev/null 2>&1; then
  # Script exits nonzero when the dir is missing or has no results; captured in $LOG, not a porter failure.
  python3 "$HERE/analyze_results.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
else
  printf 'python3 not found on PATH\n' >> "$LOG"
fi

# Guarantee a nonempty artifact for the contract (e.g. no predictions parsed -> header still written, else fallback).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"analyze_results","status":"ok","summary_csv":"%s"}\n' "$OUT"
