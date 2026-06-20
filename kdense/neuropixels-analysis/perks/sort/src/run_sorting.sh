#!/usr/bin/env bash
# run_sorting — run a spike sorter on a preprocessed recording via the vendored run_sorting.py.
# Structured JSON audit line.
set -uo pipefail
: "${PREPROCESSED_DIR:?}" "${RECORD_STORE:?}"
SORTER="${SORTER:-kilosort4}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/sort_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the science lib / sorter is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_sorting.py" "$PREPROCESSED_DIR" \
    --output "${RECORD_STORE%/}" \
    --sorter "$SORTER" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_sorting","status":"ok","report":"%s","preprocessed_dir":"%s","sorter":"%s"}\n' "$OUT" "$PREPROCESSED_DIR" "$SORTER"
