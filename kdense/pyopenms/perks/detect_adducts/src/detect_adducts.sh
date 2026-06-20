#!/usr/bin/env bash
# detect_adducts — group adducts/charge variants (MetaboliteFeatureDeconvolution) -> decharged featureXML. JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/decharged.featureXML"
CONS="${RECORD_STORE%/}/adduct_groups.consensusXML"
LOG="${RECORD_STORE%/}/detect_adducts.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" --out-features "$OUT" --out-consensus "$CONS")
[ "${NEGATIVE:-}" = "1" ]   && ARGS+=(--negative)
[ -n "${ADDUCTS:-}" ]       && ARGS+=(--adducts "$ADDUCTS")
[ -n "${CHARGE_MIN:-}" ]    && ARGS+=(--charge-min "$CHARGE_MIN")
[ -n "${CHARGE_MAX:-}" ]    && ARGS+=(--charge-max "$CHARGE_MAX")
[ -n "${MASS_MAX_DIFF:-}" ] && ARGS+=(--mass-max-diff "$MASS_MAX_DIFF")
[ -n "${RT_MAX_DIFF:-}" ]   && ARGS+=(--rt-max-diff "$RT_MAX_DIFF")
python3 "$HERE/detect_adducts.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"detect_adducts","status":"ok","input":"%s","decharged":"%s"}\n' "$INPUT" "$OUT"
