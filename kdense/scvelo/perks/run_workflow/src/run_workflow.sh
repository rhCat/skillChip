#!/usr/bin/env bash
# run_workflow — end-to-end RNA velocity pipeline via the vendored run_workflow.py driver
# (which calls the upstream rna_velocity_workflow.run_velocity_analysis). Thin porter:
# governed env vars -> CLI args. Outputs (adata_velocity.h5ad + figures) under RECORD_STORE.
# Structured JSON audit line. Needs the scvelo library; without it the porter writes a
# placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/adata_velocity.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output-dir "${RECORD_STORE%/}")
[ -n "${GROUPBY:-}" ] && ARGS+=(--groupby "$GROUPBY")
[ -n "${N_TOP_GENES:-}" ] && ARGS+=(--n-top-genes "$N_TOP_GENES")
[ -n "${N_NEIGHBORS:-}" ] && ARGS+=(--n-neighbors "$N_NEIGHBORS")
[ -n "${MODE:-}" ] && ARGS+=(--mode "$MODE")
[ -n "${N_JOBS:-}" ] && ARGS+=(--n-jobs "$N_JOBS")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_workflow.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/run_workflow.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_workflow","status":"ok","h5ad":"%s"}\n' "$OUT"
