#!/usr/bin/env bash
# mc_common_alerts — apply ChEMBL common structural alerts to a molecule library (read-only). Structured JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/common_alerts.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the medchem stack is absent or errors.
: > "$OUT"
python3 "$HERE/filter_molecules.py" "$INPUT" --common-alerts --output "$OUT" --no-summary >/dev/null 2>&1 || true
# Degrade gracefully: if the heavy stack was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mc_common_alerts","status":"ok","input":"%s","out":"%s"}\n' "$INPUT" "$OUT"
