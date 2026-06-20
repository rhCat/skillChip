#!/usr/bin/env bash
# export_sirius — SIRIUS .ms file (+ compound-info TSV) from mzML + optional featureXML. JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/export.ms"
INFO="${RECORD_STORE%/}/export_compounds.tsv"
LOG="${RECORD_STORE%/}/export_sirius.log"
: > "$OUT"
: > "$LOG"
ARGS=(sirius "$INPUT" --out "$OUT" --compound-info "$INFO")
[ -n "${FEATUREXML:-}" ] && ARGS+=(--featurexml "$FEATUREXML")
python3 "$HERE/export_gnps_sirius.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"export_sirius","status":"ok","input":"%s","ms":"%s"}\n' "$INPUT" "$OUT"
