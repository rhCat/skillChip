#!/usr/bin/env bash
# check_ngc_image — localized from NVIDIA/skills holoscan-setup (Apache-2.0). Structured-JSON audit line.
# Checks whether the NGC Holoscan container image for a CUDA tag suffix is already pulled. Read-only.
set -uo pipefail
: "${CUDA_TAG_SUFFIX:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/ngc_image.txt"
# Always (re)create $OUT so the contract's output_exists holds even if docker is absent or errors.
: > "$OUT"
bash "$HERE/check_ngc_image.impl.sh" "${CUDA_TAG_SUFFIX}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '✗ No holoscan NGC image found for variant: %s\n' "${CUDA_TAG_SUFFIX}" > "$OUT"
printf '{"tool":"check_ngc_image","status":"ok","out":"%s"}\n' "$OUT"
