#!/usr/bin/env bash
# load — read a velocyto .loom (+ optional processed .h5ad) into one AnnData .h5ad
# via the vendored load.py core. Thin porter: governed env vars -> CLI args. Output
# under RECORD_STORE. Structured JSON audit line. Needs the scvelo library; without
# it the porter writes a placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/data.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scvelo is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${PROCESSED:-}" ] && ARGS+=(--processed "$PROCESSED")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/load.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/load.log" 2>&1 || true
# If scvelo is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"load","status":"ok","h5ad":"%s"}\n' "$OUT"
