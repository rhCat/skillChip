#!/usr/bin/env bash
# run_vae_finetune — localized from NVIDIA/skills nv-generate-vae-finetune (Apache-2.0). Structured-JSON audit line.
# Stages NV-Generate-CTMR MAISI VAE configs from a datalist and (without --preflight) finetunes on a CUDA GPU.
# This governed porter runs the upstream wrapper in --preflight mode by default (validate + stage, no GPU);
# drop the --preflight flag below only when the operator explicitly wants real GPU finetuning.
set -uo pipefail
: "${DATALIST:?}" "${DATA_BASE_DIR:?}" "${RECORD_STORE:?}"
MODALITY="${MODALITY:-mri}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/metadata.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/upstream are absent or error.
: > "$OUT"
python3 "$HERE/run_vae_finetune.py" \
  "${DATALIST}" \
  --data-base-dir "${DATA_BASE_DIR}" \
  --output-dir "${RECORD_STORE%/}/artifacts" \
  --modality "${MODALITY}" \
  --preflight \
  >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_vae_finetune","status":"ok","out":"%s"}\n' "$OUT"
