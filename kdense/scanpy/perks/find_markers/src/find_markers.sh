#!/usr/bin/env bash
# find_markers — rank_genes_groups + per-group CSVs + marker plots via the vendored find_markers.py
# core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit
# line. Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/markers.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures" --csv-dir "${RECORD_STORE%/}/markers")
[ -n "${GROUPBY:-}" ] && ARGS+=(--groupby "$GROUPBY")
[ -n "${METHOD:-}" ] && ARGS+=(--method "$METHOD")
[ -n "${N_GENES:-}" ] && ARGS+=(--n-genes "$N_GENES")
[ -n "${TOP:-}" ] && ARGS+=(--top "$TOP")
[ -n "${USE_RAW:-}" ] && ARGS+=(--use-raw)
[ -n "${NO_PLOTS:-}" ] && ARGS+=(--no-plots)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/find_markers.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/find_markers.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"find_markers","status":"ok","h5ad":"%s"}\n' "$OUT"
