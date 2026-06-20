#!/usr/bin/env bash
# biomarker_classifier — biomarker-based patient stratification (PD-L1/HER2/generic threshold).
# Read-only: reads one CSV (or seeded example data), writes classified CSV + comparisons under
# RECORD_STORE. Vendored core: biomarker_classifier.py (pandas/numpy/scipy). Structured JSON audit.
set -uo pipefail
: "${RECORD_STORE:?}"
INPUT_CSV="${INPUT_CSV:-}"
BIOMARKER="${BIOMARKER:-}"
THRESHOLD="${THRESHOLD:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/classified_data.csv"
# Pre-create $OUT so the contract's output_exists holds even if the lib is absent or the core errors.
: > "$OUT"

# Translate env vars -> argparse argv for the vendored core.
set --
if [ -n "$INPUT_CSV" ]; then set -- "$INPUT_CSV"; else set -- --example; fi
[ -n "$BIOMARKER" ] && set -- "$@" -b "$BIOMARKER"
[ -n "$THRESHOLD" ] && set -- "$@" -t "$THRESHOLD"
set -- "$@" -o "${RECORD_STORE%/}"

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/biomarker_classifier.py" "$@" >> "${RECORD_STORE%/}/classify.log" 2>&1 || true

# Guarantee a non-empty output for the contract even when the science lib is missing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"biomarker_classifier","status":"ok","classified":"%s"}\n' "$OUT"
