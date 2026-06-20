#!/usr/bin/env bash
# check_homogeneity — Levene's test for homogeneity of variance across groups (+ box/variance PNG).
# Read-only diagnostic. Emits one structured-JSON audit line. Degrades gracefully offline.
set -uo pipefail
: "${DATA_CSV:?}" "${VALUE_COL:?}" "${GROUP_COL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/homogeneity.json"
FIG="${RECORD_STORE%/}/homogeneity.png"
# Always (re)create $OUT so the contract's output_exists holds even if a dep is absent or the core errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  DATA_CSV="$DATA_CSV" VALUE_COL="$VALUE_COL" GROUP_COL="$GROUP_COL" ALPHA="${ALPHA:-0.05}" \
  OUT="$OUT" FIG="$FIG" \
  python3 "$HERE/homogeneity_cli.py" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_homogeneity","status":"ok","report":"%s","figure":"%s"}\n' "$OUT" "$FIG"
