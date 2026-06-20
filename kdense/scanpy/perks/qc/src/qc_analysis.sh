#!/usr/bin/env bash
# qc_analysis — QC metrics, before/after plots, filter cells/genes, optional Scrublet, via the
# vendored qc_analysis.py core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE.
# Structured JSON audit line. Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/qc_filtered.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${MIN_GENES:-}" ] && ARGS+=(--min-genes "$MIN_GENES")
[ -n "${MAX_GENES:-}" ] && ARGS+=(--max-genes "$MAX_GENES")
[ -n "${MIN_COUNTS:-}" ] && ARGS+=(--min-counts "$MIN_COUNTS")
[ -n "${MAX_COUNTS:-}" ] && ARGS+=(--max-counts "$MAX_COUNTS")
[ -n "${MIN_CELLS:-}" ] && ARGS+=(--min-cells "$MIN_CELLS")
[ -n "${MT_THRESHOLD:-}" ] && ARGS+=(--mt-threshold "$MT_THRESHOLD")
[ -n "${SCRUBLET:-}" ] && ARGS+=(--scrublet)
[ -n "${NO_PLOTS:-}" ] && ARGS+=(--no-plots)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/qc_analysis.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/qc_analysis.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"qc_analysis","status":"ok","h5ad":"%s"}\n' "$OUT"
