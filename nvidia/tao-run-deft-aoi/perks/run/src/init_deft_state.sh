#!/usr/bin/env bash
# init_deft_state — localized from NVIDIA/skills tao-run-deft-aoi (Apache-2.0). Structured-JSON audit line.
# Seeds ${RECORD_STORE}/deft_state.json (the DEFT AOI loop's resume snapshot). This is the entry
# step; the full train/retrain/mine/gate loop is driven on top of this state by the agent + the
# vendored helper scripts in this dir. Graceful degradation: the output file is always created.
set -uo pipefail
: "${WORKSPACE:?}" "${KPI_TARGET:?}" "${MAX_ITERATIONS:?}" "${NUM_GPUS:?}" "${NUM_EPOCHS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/deft_state.json"
mkdir -p "${RECORD_STORE%/}"
: > "$OUT"

# init_deft_state.py requires --train-container OR a resolvable versions.yaml via TAO_SKILL_BANK_PATH.
# Pass an explicit placeholder when neither is available so the script reaches the write path.
TRAIN_CONTAINER_ARGS=()
if [ -z "${TAO_SKILL_BANK_PATH:-}" ]; then
  TRAIN_CONTAINER_ARGS=(--train-container "${TRAIN_CONTAINER:-nvcr.io/nvidia/tao/tao-toolkit:pyt}")
fi

python3 "$HERE/init_deft_state.py" \
  --results-dir "${RECORD_STORE%/}" \
  --workspace "${WORKSPACE}" \
  --kpi-target "${KPI_TARGET}" \
  --max-iterations "${MAX_ITERATIONS}" \
  --num-gpus "${NUM_GPUS}" \
  --num-epochs "${NUM_EPOCHS}" \
  "${TRAIN_CONTAINER_ARGS[@]}" \
  --force \
  >>"$OUT.log" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"init_deft_state","status":"ok","out":"%s"}\n' "$OUT"
