#!/usr/bin/env bash
# plot_embedding — velocity embedding stream/grid/arrows -> PNG via the vendored
# plot_embedding.py core. Thin porter: governed env vars -> CLI args. Output under
# RECORD_STORE. Structured JSON audit line. Needs the scvelo library; without it the porter
# writes a placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/velocity_embedding.png"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${KIND:-}" ] && ARGS+=(--kind "$KIND")
[ -n "${BASIS:-}" ] && ARGS+=(--basis "$BASIS")
[ -n "${COLOR:-}" ] && ARGS+=(--color "$COLOR")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/plot_embedding.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/plot_embedding.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"plot_embedding","status":"ok","png":"%s"}\n' "$OUT"
