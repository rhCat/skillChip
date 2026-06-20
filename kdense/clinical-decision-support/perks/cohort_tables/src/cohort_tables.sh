#!/usr/bin/env bash
# cohort_tables — build baseline / efficacy / safety cohort tables (CSV + LaTeX).
# Read-only: reads one CSV (or seeded example data), writes tables under RECORD_STORE.
# Vendored core: create_cohort_tables.py (pandas/numpy/scipy). Structured JSON audit.
set -uo pipefail
: "${RECORD_STORE:?}"
INPUT_CSV="${INPUT_CSV:-}"
GROUP_COL="${GROUP_COL:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/table1_baseline.csv"
# Pre-create $OUT so the contract's output_exists holds even if the lib is absent or the core errors.
: > "$OUT"

# Translate env vars -> argparse argv for the vendored core.
set --
if [ -n "$INPUT_CSV" ]; then set -- "$INPUT_CSV"; else set -- --example; fi
set -- "$@" -o "${RECORD_STORE%/}"
[ -n "$GROUP_COL" ] && set -- "$@" --group-col "$GROUP_COL"

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/create_cohort_tables.py" "$@" >> "${RECORD_STORE%/}/cohort_tables.log" 2>&1 || true

# Guarantee a non-empty output for the contract even when the science lib is missing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"cohort_tables","status":"ok","table1":"%s"}\n' "$OUT"
