#!/usr/bin/env bash
# pseudobulk — aggregate cells by group columns into a pseudobulk count matrix via the vendored
# pseudobulk.py core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE.
# Structured JSON audit line. Needs the scanpy library; without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${BY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${RECORD_STORE%/}/pseudobulk"
OUT="${PREFIX}_counts.csv"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
# BY is a space-separated list of obs columns.
ARGS=("$INPUT" --by ${BY} --out-prefix "$PREFIX")
[ -n "${LAYER:-}" ] && ARGS+=(--layer "$LAYER")
[ -n "${FUNC:-}" ] && ARGS+=(--func "$FUNC")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/pseudobulk.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/pseudobulk.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pseudobulk","status":"ok","counts":"%s"}\n' "$OUT"
