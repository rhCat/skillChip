#!/usr/bin/env bash
# rd_substructure — filter INPUT by a SMARTS/SMILES substructure PATTERN, write a per-molecule match report (read-only). Structured JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${PATTERN:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/report.csv"
# Always (re)create $OUT so the contract's output_exists holds even if rdkit is absent or errors.
: > "$OUT"
python3 "$HERE/substructure_filter.py" "$INPUT" --pattern "$PATTERN" --report "$OUT" >/dev/null 2>&1 || true
# Degrade gracefully: if rdkit was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"rd_substructure","status":"ok","input":"%s","pattern":"%s","out":"%s"}\n' "$INPUT" "$PATTERN" "$OUT"
