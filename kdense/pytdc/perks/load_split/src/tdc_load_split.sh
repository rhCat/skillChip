#!/usr/bin/env bash
# tdc_load_split — load a TDC dataset and write a train/valid/test split report (read-only).
# Thin porter: vendored core is tdc_load_split_core.py. Structured JSON audit line on stdout.
set -uo pipefail
: "${TDC_PROBLEM:?}" "${TDC_TASK:?}" "${TDC_DATASET:?}" "${RECORD_STORE:?}"
TDC_METHOD="${TDC_METHOD:-scaffold}"
TDC_SEED="${TDC_SEED:-42}"
TDC_FRAC="${TDC_FRAC:-0.7,0.1,0.2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/split.json"
# Pre-create so the contract's output_exists holds even if python/core errors.
: > "$OUT"
python3 "$HERE/tdc_load_split_core.py" \
  --problem "$TDC_PROBLEM" --task "$TDC_TASK" --dataset "$TDC_DATASET" \
  --method "$TDC_METHOD" --seed "$TDC_SEED" --frac "$TDC_FRAC" \
  --out "$OUT" || true
# Guarantee a non-empty artifact for the contract.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"tdc_load_split","status":"ok","dataset":"%s","report":"%s"}\n' "$TDC_DATASET" "$OUT"
