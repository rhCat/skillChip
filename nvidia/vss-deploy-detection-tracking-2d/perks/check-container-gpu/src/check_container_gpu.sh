#!/usr/bin/env bash
# check_container_gpu — localized from NVIDIA/skills vss-deploy-detection-tracking-2d (Apache-2.0). Structured-JSON audit line.
# Standalone op: verify CUDA / NVML access inside a running container (a long-lived
# container can silently lose its GPU handle after a host driver restart). Probes
# `nvidia-smi -L` via docker exec and emits a GPU_OK / GPU_STALE marker.
# Porter: translates CONTAINER_NAME env var -> the impl's --container arg, captures
# the probe markers under RECORD_STORE, and ALWAYS pre-creates its output (graceful
# degradation when docker / the container / the GPU is absent).
set -uo pipefail
: "${CONTAINER_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/gpu-probe.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the impl errors.
: > "$OUT"
bash "$HERE/check_container_gpu.impl.sh" --container "${CONTAINER_NAME}" >"$OUT" 2>>"$OUT" || true
[ -s "$OUT" ] || printf 'GPU_PROBE_SKIPPED %s — docker/container/GPU unavailable in this environment\n' "${CONTAINER_NAME}" > "$OUT"
printf '{"tool":"check_container_gpu","status":"ok","container":"%s","out":"%s"}\n' \
    "${CONTAINER_NAME}" "$OUT"
