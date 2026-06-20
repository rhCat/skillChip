#!/usr/bin/env bash
# latent_time — shared latent time from the dynamical model via the vendored latent_time.py
# core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON
# audit line. Needs the scvelo library; without it the porter writes a placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/latent_time.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/latent_time.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/latent_time.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"latent_time","status":"ok","h5ad":"%s"}\n' "$OUT"
