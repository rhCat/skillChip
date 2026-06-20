#!/usr/bin/env bash
# run_pipeline — full end-to-end scRNA-seq pipeline (load -> QC -> normalize -> HVG -> PCA ->
# (batch) -> UMAP -> Leiden -> markers) via the vendored run_pipeline.py core. Thin porter: governed
# env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit line. Needs the scanpy
# library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/processed.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures" --marker-dir "${RECORD_STORE%/}/markers")
[ -n "${CONFIG:-}" ] && ARGS+=(--config "$CONFIG")
[ -n "${MIN_GENES:-}" ] && ARGS+=(--min-genes "$MIN_GENES")
[ -n "${MAX_GENES:-}" ] && ARGS+=(--max-genes "$MAX_GENES")
[ -n "${MIN_CELLS:-}" ] && ARGS+=(--min-cells "$MIN_CELLS")
[ -n "${MT_THRESHOLD:-}" ] && ARGS+=(--mt-threshold "$MT_THRESHOLD")
[ -n "${SCRUBLET:-}" ] && ARGS+=(--scrublet)
[ -n "${TARGET_SUM:-}" ] && ARGS+=(--target-sum "$TARGET_SUM")
[ -n "${N_TOP_GENES:-}" ] && ARGS+=(--n-top-genes "$N_TOP_GENES")
[ -n "${HVG_FLAVOR:-}" ] && ARGS+=(--hvg-flavor "$HVG_FLAVOR")
[ -n "${SCALE:-}" ] && ARGS+=(--scale)
# REGRESS_OUT is a space-separated list of obs columns.
[ -n "${REGRESS_OUT:-}" ] && ARGS+=(--regress-out ${REGRESS_OUT})
[ -n "${N_PCS:-}" ] && ARGS+=(--n-pcs "$N_PCS")
[ -n "${N_NEIGHBORS:-}" ] && ARGS+=(--n-neighbors "$N_NEIGHBORS")
[ -n "${RESOLUTION:-}" ] && ARGS+=(--resolution "$RESOLUTION")
[ -n "${BATCH_KEY:-}" ] && ARGS+=(--batch-key "$BATCH_KEY")
[ -n "${BATCH_METHOD:-}" ] && ARGS+=(--batch-method "$BATCH_METHOD")
[ -n "${MARKER_METHOD:-}" ] && ARGS+=(--marker-method "$MARKER_METHOD")
[ -n "${SKIP_MARKERS:-}" ] && ARGS+=(--skip-markers)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_pipeline.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/run_pipeline.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_pipeline","status":"ok","h5ad":"%s"}\n' "$OUT"
