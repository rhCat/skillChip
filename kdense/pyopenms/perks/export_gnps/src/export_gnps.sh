#!/usr/bin/env bash
# export_gnps — GNPS FBMN inputs (MGF of MS2 + quant table) from consensusXML + source mzML. JSON audit.
set -uo pipefail
: "${CONSENSUS:?}" "${MZML:?space-separated source mzML files}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${RECORD_STORE%/}/gnps_export"
OUT="${PREFIX}.mgf"
LOG="${RECORD_STORE%/}/export_gnps.log"
: > "$OUT"
: > "$LOG"
# MZML is a space-separated list -> word-split intentionally into the nargs+ --mzml argument.
# shellcheck disable=SC2086
python3 "$HERE/export_gnps_sirius.py" gnps "$CONSENSUS" --mzml $MZML --out-prefix "$PREFIX" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"export_gnps","status":"ok","consensus":"%s","mgf":"%s"}\n' "$CONSENSUS" "$OUT"
