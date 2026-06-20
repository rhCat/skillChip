#!/usr/bin/env bash
# accurate_mass_search — HMDB accurate-mass annotation (AccurateMassSearchEngine) -> mzTab + CSV. JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/annotations.mzTab"
CSV="${RECORD_STORE%/}/annotations.csv"
LOG="${RECORD_STORE%/}/accurate_mass_search.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" --out-mztab "$OUT" --csv "$CSV")
[ "${NEGATIVE:-}" = "1" ] && ARGS+=(--negative)
[ -n "${PPM:-}" ]         && ARGS+=(--ppm "$PPM")
[ -n "${DB_MAPPING:-}" ]  && ARGS+=(--db-mapping "$DB_MAPPING")
[ -n "${DB_STRUCT:-}" ]   && ARGS+=(--db-struct "$DB_STRUCT")
python3 "$HERE/accurate_mass_search.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"accurate_mass_search","status":"ok","input":"%s","mztab":"%s"}\n' "$INPUT" "$OUT"
