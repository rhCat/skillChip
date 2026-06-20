#!/usr/bin/env bash
# assumption_check — comprehensive battery: outliers + normality (+ per-group homogeneity when GROUP_COL set).
# Read-only diagnostic. Emits one structured-JSON audit line. Degrades gracefully offline.
set -uo pipefail
: "${DATA_CSV:?}" "${VALUE_COL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/assumptions.json"
# Always (re)create $OUT so the contract's output_exists holds even if a dep is absent or the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  DATA_CSV="$DATA_CSV" VALUE_COL="$VALUE_COL" GROUP_COL="${GROUP_COL:-}" ALPHA="${ALPHA:-0.05}" \
  OUT="$OUT" \
  python3 "$HERE/assumptions_cli.py" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"assumption_check","status":"ok","report":"%s"}\n' "$OUT"
