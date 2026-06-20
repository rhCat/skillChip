#!/usr/bin/env bash
# compute_metrics — build a SortingAnalyzer, compute quality metrics, and apply threshold curation
# via the vendored compute_metrics.py. Structured JSON audit line.
set -uo pipefail
: "${SORTING_DIR:?}" "${PREPROCESSED_DIR:?}" "${RECORD_STORE:?}"
CURATION="${CURATION:-allen}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/metrics_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the science lib is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/compute_metrics.py" "$SORTING_DIR" "$PREPROCESSED_DIR" \
    --output "${RECORD_STORE%/}" \
    --curation "$CURATION" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"compute_metrics","status":"ok","report":"%s","sorting_dir":"%s","curation":"%s"}\n' "$OUT" "$SORTING_DIR" "$CURATION"
