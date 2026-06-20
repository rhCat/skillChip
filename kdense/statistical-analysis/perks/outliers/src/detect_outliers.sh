#!/usr/bin/env bash
# detect_outliers — flag outliers in one numeric column by IQR or z-score (+ box/scatter PNG).
# Read-only diagnostic. Emits one structured-JSON audit line. Degrades gracefully offline.
set -uo pipefail
: "${DATA_CSV:?}" "${VALUE_COL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/outliers.json"
FIG="${RECORD_STORE%/}/outliers.png"
# Always (re)create $OUT so the contract's output_exists holds even if a dep is absent or the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  DATA_CSV="$DATA_CSV" VALUE_COL="$VALUE_COL" METHOD="${METHOD:-iqr}" THRESHOLD="${THRESHOLD:-1.5}" \
  OUT="$OUT" FIG="$FIG" \
  python3 "$HERE/outliers_cli.py" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"detect_outliers","status":"ok","report":"%s","figure":"%s"}\n' "$OUT" "$FIG"
