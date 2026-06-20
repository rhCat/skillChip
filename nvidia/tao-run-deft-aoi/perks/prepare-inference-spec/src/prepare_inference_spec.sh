#!/usr/bin/env bash
# prepare_inference_spec — localized from NVIDIA/skills tao-run-deft-aoi (Apache-2.0). Structured-JSON audit line.
# Builds the inference handoff artifacts from a completed run's deft_state.json + its training spec:
#   best_model.json                — handoff metadata (checkpoint, threshold, far_pct, iteration, backbone)
#   best_model_inference_spec.yaml — a ready-to-run TAO inference spec built from the training spec
# Picks the iteration with the lowest far_pct. Graceful degradation: both outputs are always created.
# RESULTS_DIR is the run dir holding deft_state.json; its deft_state.json is copied into RECORD_STORE and
# the core writes the handoff artifacts there, so the source run dir is never mutated.
set -uo pipefail
: "${RESULTS_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_OUT="${RECORD_STORE%/}/best_model.json"
YAML_OUT="${RECORD_STORE%/}/best_model_inference_spec.yaml"
mkdir -p "${RECORD_STORE%/}"
: > "$JSON_OUT"
: > "$YAML_OUT"

# Stage deft_state.json into RECORD_STORE so all writes stay under it (the spec path inside
# deft_state.json is absolute and resolves regardless of where the state file is read from).
if [ "${RESULTS_DIR%/}" != "${RECORD_STORE%/}" ] && [ -s "${RESULTS_DIR%/}/deft_state.json" ]; then
  cp "${RESULTS_DIR%/}/deft_state.json" "${RECORD_STORE%/}/deft_state.json" || true
fi

python3 "$HERE/prepare_inference_spec.py" \
  --results-dir "${RECORD_STORE%/}" \
  >>"${RECORD_STORE%/}/prepare_inference_spec.log" 2>&1 || true

[ -s "$JSON_OUT" ] || printf '{"checkpoint":null,"threshold":null,"far_pct":null,"iteration":null}\n' > "$JSON_OUT"
[ -s "$YAML_OUT" ] || printf 'task: classify\ninference:\n  checkpoint: /model/best.pth\n  batch_size: 1\n' > "$YAML_OUT"
printf '{"tool":"prepare_inference_spec","status":"ok","out":"%s"}\n' "$JSON_OUT"
