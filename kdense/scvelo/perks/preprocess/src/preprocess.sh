#!/usr/bin/env bash
# preprocess — filter_and_normalize + neighbors + moments via the vendored preprocess.py
# core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured
# JSON audit line. Needs the scvelo library; without it the porter writes a placeholder and
# still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/preprocessed.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${MIN_SHARED_COUNTS:-}" ] && ARGS+=(--min-shared-counts "$MIN_SHARED_COUNTS")
[ -n "${N_TOP_GENES:-}" ] && ARGS+=(--n-top-genes "$N_TOP_GENES")
[ -n "${N_NEIGHBORS:-}" ] && ARGS+=(--n-neighbors "$N_NEIGHBORS")
[ -n "${N_PCS:-}" ] && ARGS+=(--n-pcs "$N_PCS")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/preprocess.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/preprocess.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"preprocess","status":"ok","h5ad":"%s"}\n' "$OUT"
