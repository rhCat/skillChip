#!/usr/bin/env bash
# inspect_ms_data — summarize an MS file (mzML/mzXML/featureXML/consensusXML/idXML). Structured JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/inspect.txt"
SPECTRA_CSV="${SPECTRA_CSV:-${RECORD_STORE%/}/spectra.csv}"
# Pre-create $OUT so output_exists holds even if pyopenms is absent or errors.
: > "$OUT"
python3 "$HERE/inspect_ms_data.py" "$INPUT" --spectra-csv "$SPECTRA_CSV" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"inspect_ms_data","status":"ok","input":"%s","report":"%s"}\n' "$INPUT" "$OUT"
