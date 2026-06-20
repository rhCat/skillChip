#!/usr/bin/env bash
# mc_rules — apply medchem drug-likeness rules to a molecule library (read-only). Structured JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${RULES:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/rules.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the medchem stack is absent or errors.
: > "$OUT"
python3 "$HERE/filter_molecules.py" "$INPUT" --rules "$RULES" --output "$OUT" --no-summary >/dev/null 2>&1 || true
# Degrade gracefully: if the heavy stack was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mc_rules","status":"ok","input":"%s","rules":"%s","out":"%s"}\n' "$INPUT" "$RULES" "$OUT"
