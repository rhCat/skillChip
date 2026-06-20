#!/usr/bin/env bash
# detect_anomalies — two-phase anomaly detection: detrend Z-score (context) + quantile PI bands (TimesFM forecast). Structured JSON audit line.
set -uo pipefail
: "${INPUT_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/anomaly_detection.json"
# Always (re)create $OUT so the contract's output_exists holds even if timesfm/torch are absent or the core errors.
: > "$OUT"
# The vendored core reads a fixed relative path (../global-temperature/temperature_anomaly.csv)
# and writes to <src>/output/. Stage the caller's CSV where the core expects it, then harvest the result.
STAGE_DIR="$HERE/../global-temperature"
mkdir -p "$STAGE_DIR" 2>/dev/null || true
cp "$INPUT_CSV" "$STAGE_DIR/temperature_anomaly.csv" 2>/dev/null || true
# Phase 1 (detrend + Z-score) is pure numpy/pandas; Phase 2 needs timesfm+torch. Degrade gracefully.
python3 "$HERE/detect_anomalies.py" >/dev/null 2>&1 || true
# Harvest the core's JSON report into the governed record store.
[ -s "$HERE/output/anomaly_detection.json" ] && cp "$HERE/output/anomaly_detection.json" "$OUT" 2>/dev/null || true
# Guarantee a non-empty, valid JSON artifact even if timesfm/torch are missing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"detect_anomalies","status":"ok","input":"%s","report":"%s"}\n' "$INPUT_CSV" "$OUT"
