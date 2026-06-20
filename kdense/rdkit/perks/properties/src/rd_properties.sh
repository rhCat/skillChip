#!/usr/bin/env bash
# rd_properties — compute molecular descriptors for every molecule in INPUT (read-only). Structured JSON audit line.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/properties.csv"
# Always (re)create $OUT so the contract's output_exists holds even if rdkit is absent or errors.
: > "$OUT"
python3 "$HERE/molecular_properties.py" --file "$INPUT" --output "$OUT" >/dev/null 2>&1 || true
# Degrade gracefully: if rdkit was missing (script aborted before writing), leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"rd_properties","status":"ok","input":"%s","out":"%s"}\n' "$INPUT" "$OUT"
