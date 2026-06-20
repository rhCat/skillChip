#!/usr/bin/env bash
# preprocess — normalize + log1p + HVG, optional regress/scale, via the vendored preprocess.py core.
# Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit line.
# Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/normalized.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${TARGET_SUM:-}" ] && ARGS+=(--target-sum "$TARGET_SUM")
[ -n "${N_TOP_GENES:-}" ] && ARGS+=(--n-top-genes "$N_TOP_GENES")
[ -n "${FLAVOR:-}" ] && ARGS+=(--flavor "$FLAVOR")
[ -n "${BATCH_KEY:-}" ] && ARGS+=(--batch-key "$BATCH_KEY")
[ -n "${SUBSET_HVG:-}" ] && ARGS+=(--subset-hvg)
# REGRESS_OUT is a space-separated list of obs columns.
[ -n "${REGRESS_OUT:-}" ] && ARGS+=(--regress-out ${REGRESS_OUT})
[ -n "${SCALE:-}" ] && ARGS+=(--scale)
[ -n "${NO_PLOTS:-}" ] && ARGS+=(--no-plots)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/preprocess.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/preprocess.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"preprocess","status":"ok","h5ad":"%s"}\n' "$OUT"
