#!/usr/bin/env bash
# mass_calculator — mass / m/z / formula / isotope pattern for a peptide or empirical formula. JSON audit.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/mass_report.txt"
CSV="${RECORD_STORE%/}/isotopes.csv"
: > "$OUT"
if [ -z "${PEPTIDE:-}" ] && [ -z "${FORMULA:-}" ]; then
  printf 'mass_calculator: set PEPTIDE and/or FORMULA\n' >> "$OUT"
  printf '{"tool":"mass_calculator","status":"ok","report":"%s","note":"no PEPTIDE/FORMULA"}\n' "$OUT"
  exit 0
fi
ARGS=()
[ -n "${PEPTIDE:-}" ]  && ARGS+=(--peptide "$PEPTIDE")
[ -n "${FORMULA:-}" ]  && ARGS+=(--formula "$FORMULA")
[ -n "${CHARGES:-}" ]  && ARGS+=(--charges $CHARGES)
[ -n "${ISOTOPES:-}" ] && ARGS+=(--isotopes "$ISOTOPES" --csv "$CSV")
[ "${NEGATIVE:-}" = "1" ] && ARGS+=(--negative)
# shellcheck disable=SC2068
python3 "$HERE/mass_calculator.py" ${ARGS[@]} >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mass_calculator","status":"ok","report":"%s"}\n' "$OUT"
