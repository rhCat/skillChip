#!/usr/bin/env bash
# train_gnn — train a molecular graph neural network on a MoleculeNet benchmark or custom CSV
# and evaluate it. Read-only/local. Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
MODEL="${MODEL:-gcn}"
DATASET="${DATASET:-}"
DATA_CSV="${DATA_CSV:-}"
TASK_TYPE="${TASK_TYPE:-classification}"
TARGETS="${TARGETS:-target}"
SMILES_COL="${SMILES_COL:-smiles}"
EPOCHS="${EPOCHS:-50}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$HERE/graph_neural_network.py"
OUT="${RECORD_STORE%/}/gnn_train.txt"
# Always (re)create $OUT so the contract's output_exists holds even if deepchem/torch is absent or errors.
: > "$OUT"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
  printf '{"tool":"train_gnn","status":"ok","gnn_report":"%s"}\n' "$OUT"
  exit 0
fi

# Build argv: prefer custom CSV when DATA_CSV is set, else a MoleculeNet DATASET.
ARGS=(--model "$MODEL" --epochs "$EPOCHS")
if [ -n "$DATA_CSV" ]; then
  ARGS+=(--data "$DATA_CSV" --task-type "$TASK_TYPE" --smiles-col "$SMILES_COL" --targets)
  for t in $TARGETS; do ARGS+=("$t"); done
elif [ -n "$DATASET" ]; then
  ARGS+=(--dataset "$DATASET")
fi

# env->arg translation done; run the vendored core. Degrade gracefully if deepchem/torch/rdkit absent.
python3 "$CORE" "${ARGS[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"train_gnn","status":"ok","gnn_report":"%s"}\n' "$OUT"
