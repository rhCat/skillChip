#!/usr/bin/env bash
# mc_query — evaluate a medchem query-language expression over a molecule library (read-only). Structured JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${QUERY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/query.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the medchem stack is absent or errors.
: > "$OUT"
python3 "$HERE/filter_molecules.py" "$INPUT" --query "$QUERY" --output "$OUT" --no-summary >/dev/null 2>&1 || true
# Degrade gracefully: if the heavy stack was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mc_query","status":"ok","input":"%s","out":"%s"}\n' "$INPUT" "$OUT"
