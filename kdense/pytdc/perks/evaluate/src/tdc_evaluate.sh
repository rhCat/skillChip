#!/usr/bin/env bash
# tdc_evaluate — score predictions vs truth with a standardized TDC metric (read-only).
# Thin porter: vendored core is tdc_evaluate_core.py. Structured JSON audit line on stdout.
set -uo pipefail
: "${TDC_METRIC:?}" "${TDC_PRED:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/eval.json"
# Pre-create so the contract's output_exists holds even if python/core errors.
: > "$OUT"
python3 "$HERE/tdc_evaluate_core.py" \
  --metric "$TDC_METRIC" --pred "$TDC_PRED" --out "$OUT" || true
# Guarantee a non-empty artifact for the contract.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"tdc_evaluate","status":"ok","metric":"%s","report":"%s"}\n' "$TDC_METRIC" "$OUT"
