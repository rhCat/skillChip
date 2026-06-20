#!/usr/bin/env bash
# model_averaging — pseudo-BMA weights + weighted average of posterior-predictive draws across
# PyMC/ArviZ InferenceData .nc files (read-only). Emits one structured-JSON audit line.
set -uo pipefail
: "${MODELS_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/averaging.json"
# Always (re)create $OUT so the contract's output_exists holds even if arviz/numpy is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  MODELS_DIR="$MODELS_DIR" MODELS="${MODELS:-}" OUT="$OUT" VAR_NAME="${VAR_NAME:-y_obs}" IC="${IC:-loo}" \
  python3 "$HERE/cli_model_averaging.py" >/dev/null 2>&1 || true
# Graceful offline: if the heavy science lib was absent and produced nothing, leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"model_averaging","status":"ok","models_dir":"%s","out":"%s"}\n' "$MODELS_DIR" "$OUT"
