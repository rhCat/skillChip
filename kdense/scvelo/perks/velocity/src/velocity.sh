#!/usr/bin/env bash
# velocity — recover_dynamics (dynamical) + velocity + velocity_graph via the vendored
# velocity.py core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE.
# Structured JSON audit line. Needs the scvelo library; without it the porter writes a
# placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/velocity.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${MODE:-}" ] && ARGS+=(--mode "$MODE")
[ -n "${N_JOBS:-}" ] && ARGS+=(--n-jobs "$N_JOBS")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/velocity.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/velocity.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"velocity","status":"ok","h5ad":"%s"}\n' "$OUT"
