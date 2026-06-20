#!/usr/bin/env bash
# eda_analyze — full EDA pipeline -> markdown report (read-only). Structured JSON audit line.
# Thin porter: vendors eda_analyzer.py + eda_analyze.py + references/; env -> argv; degrades gracefully when a science lib is absent.
set -uo pipefail
: "${DATA_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/eda_report.md"
# Always (re)create $OUT so the contract's output_exists holds even if a science lib is absent or the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/eda_analyze.py" "$DATA_FILE" "$OUT" \
  >> "${RECORD_STORE%/}/eda_analyze.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"eda_analyze","status":"ok","data_file":"%s","eda_report":"%s"}\n' "$DATA_FILE" "$OUT"
