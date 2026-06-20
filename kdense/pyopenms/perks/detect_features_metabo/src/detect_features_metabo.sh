#!/usr/bin/env bash
# detect_features_metabo — untargeted metabolomics feature finding (MTD->EPD->FFM). Structured JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/features.featureXML"
CSV="${RECORD_STORE%/}/features.csv"
LOG="${RECORD_STORE%/}/detect_features_metabo.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" --out-features "$OUT" --out-csv "$CSV")
[ -n "${PPM:-}" ]         && ARGS+=(--ppm "$PPM")
[ -n "${NOISE:-}" ]       && ARGS+=(--noise "$NOISE")
[ -n "${CHARGE_LOW:-}" ]  && ARGS+=(--charge-low "$CHARGE_LOW")
[ -n "${CHARGE_HIGH:-}" ] && ARGS+=(--charge-high "$CHARGE_HIGH")
[ "${KEEP_SINGLETONS:-}" = "1" ] && ARGS+=(--keep-singletons)
[ -n "${ISO_MODEL:-}" ]   && ARGS+=(--iso-model "$ISO_MODEL")
python3 "$HERE/detect_features_metabo.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"detect_features_metabo","status":"ok","input":"%s","features":"%s"}\n' "$INPUT" "$OUT"
