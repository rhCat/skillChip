#!/usr/bin/env bash
# run_ct_image — localized from NVIDIA/skills nv-generate-ct-rflow (Apache-2.0). Structured-JSON audit line.
# Thin porter: env vars -> run_ct_image.py CLI. CT image-only generation (no paired labels) via upstream
# scripts.diff_model_infer (GPU). MODEL_CONFIG is an override JSON (dim/spacing/region indices/steps/cfg) or
# 'default'. The wrapper emits result JSON to stdout (captured as result.json); generated *.nii.gz land under
# --output-dir (RECORD_STORE/samples). PREFLIGHT=1 validates the rendered config + dataset/CUDA presence and
# previews cost without launching inference.
set -uo pipefail
: "${MODEL_CONFIG:?}" "${NV_GENERATE_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
SAMPLES="${RECORD_STORE%/}/samples"
: > "$OUT"
mkdir -p "$SAMPLES"
export NV_GENERATE_ROOT
ARGS=("${MODEL_CONFIG}" --output-dir "$SAMPLES" --version "${VERSION:-rflow-ct}" --random-seed "${RANDOM_SEED:-0}")
# Inference is GPU-heavy and cost-gated; default to preflight so an unconfirmed/offline run degrades to a
# parseable validation report. Set PREFLIGHT=0 (and CONFIRM=1 for heavy runs) to actually generate the image.
if [ "${PREFLIGHT:-1}" = "1" ]; then ARGS+=(--preflight-only); fi
[ "${CONFIRM:-}" = "1" ] && ARGS+=(--yes)
python3 "$HERE/run_ct_image.py" "${ARGS[@]}" >"$OUT" 2>>"$OUT.log" || true
# Graceful degradation: always leave a parseable result.json even if the wrapper aborted early.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_ct_image","status":"ok","out":"%s"}\n' "$OUT"
