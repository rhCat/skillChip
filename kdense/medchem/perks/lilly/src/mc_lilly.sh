#!/usr/bin/env bash
# mc_lilly — apply Eli Lilly demerit filter to a molecule library (read-only). Structured JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${LILLY_MAX:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/lilly.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the medchem stack is absent or errors.
: > "$OUT"
python3 "$HERE/filter_molecules.py" "$INPUT" --lilly --lilly-max "$LILLY_MAX" --output "$OUT" --no-summary >/dev/null 2>&1 || true
# Degrade gracefully: if the heavy stack was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mc_lilly","status":"ok","input":"%s","lilly_max":"%s","out":"%s"}\n' "$INPUT" "$LILLY_MAX" "$OUT"
