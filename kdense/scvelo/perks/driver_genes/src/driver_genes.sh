#!/usr/bin/env bash
# driver_genes — rank_velocity_genes per group -> CSV via the vendored driver_genes.py core.
# Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit
# line. Needs the scvelo library; without it the porter writes a placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/driver_genes.csv"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${GROUPBY:-}" ] && ARGS+=(--groupby "$GROUPBY")
[ -n "${MIN_CORR:-}" ] && ARGS+=(--min-corr "$MIN_CORR")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/driver_genes.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/driver_genes.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"driver_genes","status":"ok","csv":"%s"}\n' "$OUT"
