#!/usr/bin/env bash
# detect_features_centroided — peptide/centroided feature detection (FeatureFinderAlgorithmPicked). JSON audit.
set -uo pipefail
: "${INPUT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/features.featureXML"
CSV="${RECORD_STORE%/}/features.csv"
LOG="${RECORD_STORE%/}/detect_features_centroided.log"
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" --out-features "$OUT" --out-csv "$CSV")
[ -n "${MZ_TOL_PPM:-}" ]  && ARGS+=(--mz-tol-ppm "$MZ_TOL_PPM")
[ -n "${CHARGE_LOW:-}" ]  && ARGS+=(--charge-low "$CHARGE_LOW")
[ -n "${CHARGE_HIGH:-}" ] && ARGS+=(--charge-high "$CHARGE_HIGH")
[ -n "${MIN_SPECTRA:-}" ] && ARGS+=(--min-spectra "$MIN_SPECTRA")
python3 "$HERE/detect_features_centroided.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"detect_features_centroided","status":"ok","input":"%s","features":"%s"}\n' "$INPUT" "$OUT"
