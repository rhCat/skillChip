#!/usr/bin/env bash
# run_rflow_ct_preflight — localized from NVIDIA/skills nv-generate-ct-rflow (Apache-2.0). Structured-JSON audit line.
# Thin porter: env vars -> run_rflow_ct.py --preflight-only. Validates a config_infer override (schema bounds,
# anatomy/body_region names, FOV minimums, dataset + CUDA presence) and previews estimated VRAM/wall-time WITHOUT
# launching diffusion inference. The python wrapper emits its preflight report JSON to stdout; we capture it as
# preflight.json under RECORD_STORE. No GPU is required to preview — missing CUDA/datasets surface as JSON errors.
set -uo pipefail
: "${CONFIG_INFER:?}" "${NV_GENERATE_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/preflight.json"
STAGE="${RECORD_STORE%/}/staged"
: > "$OUT"
mkdir -p "$STAGE"
export NV_GENERATE_ROOT
python3 "$HERE/run_rflow_ct.py" "${CONFIG_INFER}" \
  --output-dir "$STAGE" \
  --version "${VERSION:-rflow-ct}" \
  --preflight-only \
  >"$OUT" 2>>"$OUT.log" || true
# Graceful degradation: always leave a parseable preflight.json even if the wrapper aborted early.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_rflow_ct_preflight","status":"ok","out":"%s"}\n' "$OUT"
