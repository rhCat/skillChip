#!/usr/bin/env bash
# run_ct_mask — localized from NVIDIA/skills nv-generate-ct-rflow (Apache-2.0). Structured-JSON audit line.
# Thin porter: env vars -> run_ct_mask.py CLI. Standalone raw MAISI-space CT mask generation from
# controllable anatomy-size conditions via upstream mask diffusion (GPU). Diagnostic mode: produces label
# masks before image generation, not paired CT images. The wrapper emits result JSON to stdout (captured as
# result.json); generated mask_*.nii.gz land under --output-dir (RECORD_STORE/samples). PREFLIGHT=1 validates
# the request + dataset/CUDA presence and exits without sampling.
set -uo pipefail
: "${REQUEST_JSON:?}" "${NV_GENERATE_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
SAMPLES="${RECORD_STORE%/}/samples"
: > "$OUT"
mkdir -p "$SAMPLES"
export NV_GENERATE_ROOT
ARGS=("${REQUEST_JSON}" --output-dir "$SAMPLES" --random-seed "${RANDOM_SEED:-0}")
# Generation is GPU-heavy and gated behind --yes; default to preflight so an unconfirmed/offline run
# degrades to a parseable validation report. Set PREFLIGHT=0 and CONFIRM=1 to actually sample masks.
if [ "${PREFLIGHT:-1}" = "1" ]; then ARGS+=(--preflight-only); fi
[ "${CONFIRM:-}" = "1" ] && ARGS+=(--yes)
python3 "$HERE/run_ct_mask.py" "${ARGS[@]}" >"$OUT" 2>>"$OUT.log" || true
# Graceful degradation: always leave a parseable result.json even if the wrapper aborted early.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_ct_mask","status":"ok","out":"%s"}\n' "$OUT"
