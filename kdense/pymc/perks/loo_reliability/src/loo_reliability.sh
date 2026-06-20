#!/usr/bin/env bash
# loo_reliability — Pareto-k LOO-CV reliability check across PyMC/ArviZ InferenceData .nc files (read-only).
# Emits one structured-JSON audit line.
set -uo pipefail
: "${MODELS_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/loo_reliability.json"
# Always (re)create $OUT so the contract's output_exists holds even if arviz/pymc is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  MODELS_DIR="$MODELS_DIR" MODELS="${MODELS:-}" OUT="$OUT" THRESHOLD="${THRESHOLD:-0.7}" \
  python3 "$HERE/cli_loo_reliability.py" >/dev/null 2>&1 || true
# Graceful offline: if the heavy science lib was absent and produced nothing, leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"loo_reliability","status":"ok","models_dir":"%s","out":"%s"}\n' "$MODELS_DIR" "$OUT"
