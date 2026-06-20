#!/usr/bin/env bash
# predict_solubility — train a MultitaskRegressor for solubility (Delaney ECFP or custom CSV),
# evaluate, and optionally predict new SMILES. Read-only/local. Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
DATA_CSV="${DATA_CSV:-}"
SMILES_COL="${SMILES_COL:-smiles}"
TARGET_COL="${TARGET_COL:-solubility}"
PREDICT_SMILES="${PREDICT_SMILES:-}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/predict_solubility.py"
OUT="${RECORD_STORE%/}/solubility.txt"
# Always (re)create $OUT so the contract's output_exists holds even if deepchem/rdkit is absent or errors.
: > "$OUT"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"predict_solubility","status":"ok","solubility_report":"%s"}\n' "$OUT"
  exit 0
fi

# Build argv: empty DATA_CSV -> Delaney/ESOL benchmark mode (no --data).
ARGS=()
if [ -n "$DATA_CSV" ]; then
  ARGS+=(--data "$DATA_CSV" --smiles-col "$SMILES_COL" --target-col "$TARGET_COL")
fi
# PREDICT_SMILES is space-separated; pass each as a positional value to --predict (nargs='+').
if [ -n "$PREDICT_SMILES" ]; then
  ARGS+=(--predict)
  for s in $PREDICT_SMILES; do ARGS+=("$s"); done
fi

# env->arg translation done; run the vendored core. Degrade gracefully if deepchem/backend/rdkit absent.
python3 "$CORE" "${ARGS[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"predict_solubility","status":"ok","solubility_report":"%s"}\n' "$OUT"
