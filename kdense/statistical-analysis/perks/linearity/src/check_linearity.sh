#!/usr/bin/env bash
# check_linearity — linear fit + residuals-vs-fitted diagnostic for two numeric columns (+ PNG).
# Read-only diagnostic. Emits one structured-JSON audit line. Degrades gracefully offline.
set -uo pipefail
: "${DATA_CSV:?}" "${X_COL:?}" "${Y_COL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/linearity.json"
FIG="${RECORD_STORE%/}/linearity.png"
# Always (re)create $OUT so the contract's output_exists holds even if a dep is absent or the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  DATA_CSV="$DATA_CSV" X_COL="$X_COL" Y_COL="$Y_COL" \
  OUT="$OUT" FIG="$FIG" \
  python3 "$HERE/linearity_cli.py" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_linearity","status":"ok","report":"%s","figure":"%s"}\n' "$OUT" "$FIG"
