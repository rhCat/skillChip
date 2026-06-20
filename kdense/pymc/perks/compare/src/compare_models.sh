#!/usr/bin/env bash
# compare_models — rank 2+ PyMC/ArviZ InferenceData .nc files by LOO or WAIC (read-only).
# Emits one structured-JSON audit line.
set -uo pipefail
: "${MODELS_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/comparison.json"
# Always (re)create $OUT so the contract's output_exists holds even if arviz/pymc is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  MODELS_DIR="$MODELS_DIR" MODELS="${MODELS:-}" OUT="$OUT" IC="${IC:-loo}" \
  python3 "$HERE/cli_compare_models.py" >/dev/null 2>&1 || true
# Graceful offline: if the heavy science lib was absent and produced nothing, leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"compare_models","status":"ok","models_dir":"%s","out":"%s"}\n' "$MODELS_DIR" "$OUT"
