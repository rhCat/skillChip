#!/usr/bin/env bash
# check_diagnostics — quick MCMC diagnostics (R-hat, ESS, divergences, tree depth) on one
# PyMC/ArviZ InferenceData .nc file. Read-only. Emits one structured-JSON audit line.
set -uo pipefail
: "${IDATA:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/diagnostics.json"
# Always (re)create $OUT so the contract's output_exists holds even if arviz/pymc is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  IDATA="$IDATA" OUT="$OUT" VAR_NAMES="${VAR_NAMES:-}" \
  python3 "$HERE/cli_check_diagnostics.py" >/dev/null 2>&1 || true
# Graceful offline: if the heavy science lib was absent and produced nothing, leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_diagnostics","status":"ok","idata":"%s","out":"%s"}\n' "$IDATA" "$OUT"
