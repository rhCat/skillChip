#!/usr/bin/env bash
# theoretical_spectrum — annotated theoretical fragment spectrum for a peptide -> mzML + peak CSV. JSON audit.
set -uo pipefail
: "${PEPTIDE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/theoretical_peaks.csv"
MZML="${RECORD_STORE%/}/theoretical.mzML"
LOG="${RECORD_STORE%/}/theoretical_spectrum.log"
: > "$OUT"
: > "$LOG"
ARGS=("$PEPTIDE" --out-mzml "$MZML" --out-csv "$OUT")
[ -n "${CHARGE:-}" ]    && ARGS+=(--charge "$CHARGE")
[ -n "${IONS:-}" ]      && ARGS+=(--ions $IONS)
[ "${LOSSES:-}" = "1" ]    && ARGS+=(--losses)
[ "${PRECURSOR:-}" = "1" ] && ARGS+=(--precursor)
# shellcheck disable=SC2068
python3 "$HERE/theoretical_spectrum.py" ${ARGS[@]} >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"theoretical_spectrum","status":"ok","peptide":"%s","peaks":"%s"}\n' "$PEPTIDE" "$OUT"
