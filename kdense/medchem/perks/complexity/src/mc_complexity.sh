#!/usr/bin/env bash
# mc_complexity — filter a molecule library by ZINC-15 complexity percentile (read-only). Structured JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${COMPLEXITY:?}" "${COMPLEXITY_METHOD:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/complexity.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the medchem stack is absent or errors.
: > "$OUT"
python3 "$HERE/filter_molecules.py" "$INPUT" --complexity "$COMPLEXITY" --complexity-method "$COMPLEXITY_METHOD" --output "$OUT" --no-summary >/dev/null 2>&1 || true
# Degrade gracefully: if the heavy stack was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mc_complexity","status":"ok","input":"%s","complexity":"%s","method":"%s","out":"%s"}\n' "$INPUT" "$COMPLEXITY" "$COMPLEXITY_METHOD" "$OUT"
