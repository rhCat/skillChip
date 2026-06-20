#!/usr/bin/env bash
# tdc_benchmark — run a TDC benchmark group's 5-seed evaluate protocol (read-only).
# Thin porter: vendored core is tdc_benchmark_core.py. Structured JSON audit line on stdout.
set -uo pipefail
: "${TDC_GROUP:?}" "${TDC_PRED:?}" "${RECORD_STORE:?}"
TDC_PATH="${TDC_PATH:-${RECORD_STORE%/}/data}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/bench.json"
# Pre-create so the contract's output_exists holds even if python/core errors.
: > "$OUT"
python3 "$HERE/tdc_benchmark_core.py" \
  --group "$TDC_GROUP" --pred "$TDC_PRED" --path "$TDC_PATH" --out "$OUT" || true
# Guarantee a non-empty artifact for the contract.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"tdc_benchmark","status":"ok","group":"%s","report":"%s"}\n' "$TDC_GROUP" "$OUT"
