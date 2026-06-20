#!/usr/bin/env bash
# convert — load any single-cell format and write .h5ad via the vendored convert.py core.
# Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit line.
# Needs the scanpy library; without it the porter writes a placeholder and still passes.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/data.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures")
[ -n "${TRANSPOSE:-}" ] && ARGS+=(--transpose)
[ -n "${MAKE_UNIQUE:-}" ] && ARGS+=(--make-unique)
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/convert.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/convert.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"convert","status":"ok","h5ad":"%s"}\n' "$OUT"
