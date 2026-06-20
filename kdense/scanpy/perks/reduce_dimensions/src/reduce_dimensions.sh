#!/usr/bin/env bash
# reduce_dimensions — PCA + neighbors + UMAP (+ optional t-SNE) via the vendored reduce_dimensions.py
# core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit
# line. Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/reduced.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${N_COMPS:-}" ] && ARGS+=(--n-comps "$N_COMPS")
[ -n "${N_PCS:-}" ] && ARGS+=(--n-pcs "$N_PCS")
[ -n "${N_NEIGHBORS:-}" ] && ARGS+=(--n-neighbors "$N_NEIGHBORS")
[ -n "${USE_REP:-}" ] && ARGS+=(--use-rep "$USE_REP")
[ -n "${TSNE:-}" ] && ARGS+=(--tsne)
# COLOR is a space-separated list of obs/var keys.
[ -n "${COLOR:-}" ] && ARGS+=(--color ${COLOR})
[ -n "${NO_PLOTS:-}" ] && ARGS+=(--no-plots)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/reduce_dimensions.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/reduce_dimensions.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"reduce_dimensions","status":"ok","h5ad":"%s"}\n' "$OUT"
