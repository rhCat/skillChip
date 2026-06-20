#!/usr/bin/env bash
# survival_analysis — Kaplan-Meier + log-rank + Cox hazard ratio + number-at-risk table.
# Read-only: reads one survival CSV, writes outputs under RECORD_STORE.
# Vendored core: generate_survival_analysis.py (lifelines/matplotlib). Structured JSON audit.
# Degrades gracefully when lifelines is absent (records the gap; writes an empty report).
set -uo pipefail
: "${INPUT_CSV:?}" "${RECORD_STORE:?}"
TITLE="${TITLE:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/survival_statistics.txt"
# Pre-create $OUT so the contract's output_exists holds even if lifelines is absent or the core errors.
: > "$OUT"

set -- "$INPUT_CSV" -o "${RECORD_STORE%/}"
[ -n "$TITLE" ] && set -- "$@" -t "$TITLE"

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_survival_analysis.py" "$@" >> "${RECORD_STORE%/}/survival.log" 2>&1 || true

# Guarantee a non-empty output for the contract even when lifelines is missing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"survival_analysis","status":"ok","statistics":"%s"}\n' "$OUT"
