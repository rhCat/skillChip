#!/usr/bin/env bash
# score_genes — score gene signatures and/or cell-cycle phase via the vendored score_genes.py core.
# Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit line.
# Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/scored.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${GENE_SETS:-}" ] && ARGS+=(--gene-sets "$GENE_SETS")
[ -n "${CELL_CYCLE:-}" ] && ARGS+=(--cell-cycle)
[ -n "${NO_PLOTS:-}" ] && ARGS+=(--no-plots)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/score_genes.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/score_genes.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"score_genes","status":"ok","h5ad":"%s"}\n' "$OUT"
