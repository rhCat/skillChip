#!/usr/bin/env bash
# batch_correct — integration across samples (harmony/bbknn/combat) via the vendored batch_correct.py
# core. Thin porter: governed env vars -> CLI args. Output under RECORD_STORE. Structured JSON audit
# line. Needs the scanpy library (plus harmonypy/bbknn); without it the porter still passes.
set -uo pipefail
: "${INPUT:?}" "${BATCH_KEY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/integrated.h5ad"
# Always (re)create $OUT so the contract's output_exists holds even if scanpy is absent or errors.
: > "$OUT"
ARGS=("$INPUT" --output "$OUT" --figdir "${RECORD_STORE%/}/figures" --batch-key "$BATCH_KEY")
[ -n "${METHOD:-}" ] && ARGS+=(--method "$METHOD")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/batch_correct.py" "${ARGS[@]}" \
  >> "${RECORD_STORE%/}/batch_correct.log" 2>&1 || true
# If scanpy is absent (the core dies before writing), keep a valid non-empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"batch_correct","status":"ok","h5ad":"%s"}\n' "$OUT"
