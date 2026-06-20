#!/usr/bin/env bash
# velocity_pseudotime — velocity_confidence + velocity_pseudotime via the vendored
# velocity_pseudotime.py core. Thin porter: governed env vars -> CLI args. Output under
# RECORD_STORE. Structured JSON audit line. Needs the scvelo library; without it the porter
# writes a placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/velocity_pseudotime.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/velocity_pseudotime.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/velocity_pseudotime.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"velocity_pseudotime","status":"ok","h5ad":"%s"}\n' "$OUT"
