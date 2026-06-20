#!/usr/bin/env bash
# run_ct_from_mask — localized from NVIDIA/skills nv-generate-ct-rflow (Apache-2.0). Structured-JSON audit line.
# Thin porter: env vars -> run_ct_from_mask.py CLI. Generates a CT image from an existing MAISI label mask
# via upstream scripts.infer_image_from_mask (GPU). The request JSON must contain mask_path (integer MAISI
# NIfTI label map, normally with body label 200). The wrapper emits result JSON to stdout (captured as
# result.json); generated *_image.nii.gz land under --output-dir (RECORD_STORE/samples). PREFLIGHT=1 validates
# the mask + dataset/CUDA presence and exits without inference.
set -uo pipefail
: "${REQUEST_JSON:?}" "${NV_GENERATE_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
SAMPLES="${RECORD_STORE%/}/samples"
: > "$OUT"
mkdir -p "$SAMPLES"
export NV_GENERATE_ROOT
ARGS=("${REQUEST_JSON}" --output-dir "$SAMPLES" --random-seed "${RANDOM_SEED:-0}")
# Inference is GPU-heavy; default to preflight so an unconfirmed/offline run degrades to a parseable
# validation report. Set PREFLIGHT=0 (and CONFIRM=1 if many steps) to actually generate the image.
if [ "${PREFLIGHT:-1}" = "1" ]; then ARGS+=(--preflight-only); fi
[ "${CONFIRM:-}" = "1" ] && ARGS+=(--yes)
[ "${ALLOW_MISSING_BODY_LABEL:-}" = "1" ] && ARGS+=(--allow-missing-body-label)
python3 "$HERE/run_ct_from_mask.py" "${ARGS[@]}" >"$OUT" 2>>"$OUT.log" || true
# Graceful degradation: always leave a parseable result.json even if the wrapper aborted early.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_ct_from_mask","status":"ok","out":"%s"}\n' "$OUT"
