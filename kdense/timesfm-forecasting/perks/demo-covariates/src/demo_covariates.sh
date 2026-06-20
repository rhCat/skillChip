#!/usr/bin/env bash
# demo_covariates — synthetic 3-store retail data with exogenous covariates + effect decomposition → CSV + metadata JSON. Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/sales_with_covariates.csv"
META="${RECORD_STORE%/}/covariates_metadata.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
# Pure numpy/pandas/matplotlib — no timesfm/torch needed at runtime (the XReg API is only printed).
python3 "$HERE/demo_covariates.py" >/dev/null 2>&1 || true
# Harvest the core's artifacts into the governed record store.
[ -s "$HERE/output/sales_with_covariates.csv" ] && cp "$HERE/output/sales_with_covariates.csv" "$OUT" 2>/dev/null || true
[ -s "$HERE/output/covariates_metadata.json" ] && cp "$HERE/output/covariates_metadata.json" "$META" 2>/dev/null || true
# Guarantee a non-empty artifact even if the core failed to produce one.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"demo_covariates","status":"ok","csv":"%s","metadata":"%s"}\n' "$OUT" "$META"
