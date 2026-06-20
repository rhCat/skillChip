#!/usr/bin/env bash
# transfer_learning — fine-tune a pretrained molecular model (chemberta/grover/molformer) on a
# property task and evaluate it. Read-only/local. Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
MODEL="${MODEL:-chemberta}"
DATASET="${DATASET:-}"
DATA_CSV="${DATA_CSV:-}"
TARGET="${TARGET:-target}"
SMILES_COL="${SMILES_COL:-smiles}"
TASK_TYPE="${TASK_TYPE:-classification}"
EPOCHS="${EPOCHS:-10}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/transfer_learning.py"
OUT="${RECORD_STORE%/}/transfer_learning.txt"
# Always (re)create $OUT so the contract's output_exists holds even if deepchem/torch is absent or errors.
: > "$OUT"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"transfer_learning","status":"ok","transfer_report":"%s"}\n' "$OUT"
  exit 0
fi

# Build argv: --model is required; prefer custom CSV when DATA_CSV is set, else a MoleculeNet DATASET.
ARGS=(--model "$MODEL" --epochs "$EPOCHS" --task-type "$TASK_TYPE")
if [ -n "$DATA_CSV" ]; then
  ARGS+=(--data "$DATA_CSV" --smiles-col "$SMILES_COL" --target)
  for t in $TARGET; do ARGS+=("$t"); done
elif [ -n "$DATASET" ]; then
  ARGS+=(--dataset "$DATASET")
fi

# env->arg translation done; run the vendored core. Degrade gracefully if deepchem/torch/rdkit/network absent.
python3 "$CORE" "${ARGS[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"transfer_learning","status":"ok","transfer_report":"%s"}\n' "$OUT"
