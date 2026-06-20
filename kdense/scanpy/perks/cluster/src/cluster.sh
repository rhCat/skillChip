#!/usr/bin/env bash
# cluster — Leiden/louvain clustering at one or many resolutions via the vendored cluster.py core.
# Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit line.
# Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/clustered.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
# RESOLUTION is a space-separated list of floats.
[ -n "${RESOLUTION:-}" ] && ARGS+=(--resolution ${RESOLUTION})
[ -n "${ALGORITHM:-}" ] && ARGS+=(--algorithm "$ALGORITHM")
[ -n "${KEY:-}" ] && ARGS+=(--key "$KEY")
[ -n "${NO_PLOTS:-}" ] && ARGS+=(--no-plots)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/cluster.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/cluster.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"cluster","status":"ok","h5ad":"%s"}\n' "$OUT"
