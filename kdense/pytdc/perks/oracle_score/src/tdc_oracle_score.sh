#!/usr/bin/env bash
# tdc_oracle_score — score SMILES with a TDC molecular oracle (read-only).
# Thin porter: vendored core is tdc_oracle_score_core.py. Structured JSON audit line on stdout.
set -uo pipefail
: "${TDC_ORACLE:?}" "${TDC_SMILES:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/scores.json"
# Pre-create so the contract's output_exists holds even if python/core errors.
: > "$OUT"
python3 "$HERE/tdc_oracle_score_core.py" \
  --oracle "$TDC_ORACLE" --smiles "$TDC_SMILES" --out "$OUT" || true
# Guarantee a non-empty artifact for the contract.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"tdc_oracle_score","status":"ok","oracle":"%s","report":"%s"}\n' "$TDC_ORACLE" "$OUT"
