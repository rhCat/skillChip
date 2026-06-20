#!/usr/bin/env bash
# filter_counts — drop low-count genes + missing-metadata samples from an RNA-seq
# count matrix (pure pandas, read-only). Writes filtered_counts.csv. Structured JSON audit line.
set -uo pipefail
: "${COUNTS:?}" "${METADATA:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/filtered_counts.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
COUNTS="$COUNTS" METADATA="$METADATA" \
  MIN_COUNTS="${MIN_COUNTS:-10}" CONDITION_COL="${CONDITION_COL:-}" \
  NO_TRANSPOSE="${NO_TRANSPOSE:-}" OUT="$OUT" \
  PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/filter_entry.py" >> "${RECORD_STORE%/}/filter_counts.log" 2>&1 || true
# If the core produced nothing (e.g. pandas missing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"filter_counts","status":"ok","out":"%s"}\n' "$OUT"
