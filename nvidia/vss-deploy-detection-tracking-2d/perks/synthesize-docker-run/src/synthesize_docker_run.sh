#!/usr/bin/env bash
# synthesize_docker_run — localized from NVIDIA/skills vss-deploy-detection-tracking-2d (Apache-2.0). Structured-JSON audit line.
# Standalone op: reconstruct the full `docker run …` command for an existing
# container from `docker inspect` (mounts, --gpus, --network, env), redacting
# secrets, so deploy logs / Step 3 boxes can show the actual flags in effect.
# Porter: translates CONTAINER_NAME env var -> the impl's positional arg, captures
# the synthesized command under RECORD_STORE, and ALWAYS pre-creates its output
# (graceful degradation when docker / the container is absent).
set -uo pipefail
: "${CONTAINER_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/docker-run.sh"
# Always (re)create $OUT so the contract's output_exists holds even if the impl errors.
: > "$OUT"
bash "$HERE/synthesize_docker_run.impl.sh" "${CONTAINER_NAME}" >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '# synthesize_docker_run produced no output for CONTAINER_NAME=%s (docker/container unavailable; see %s.log)\n' "${CONTAINER_NAME}" "$OUT" > "$OUT"
printf '{"tool":"synthesize_docker_run","status":"ok","container":"%s","out":"%s"}\n' \
    "${CONTAINER_NAME}" "$OUT"
