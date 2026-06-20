#!/usr/bin/env bash
# load_defaults — localized from NVIDIA/skills vss-deploy-detection-tracking-2d (Apache-2.0). Structured-JSON audit line.
# Step 1.b/1.c of the DEPLOY flow: detect host platform and resolve the per-use-case
# deployment defaults (image, NGC model/video refs, GPU id) from assets/deploy-defaults.yml.
# Porter: translates USECASE env var -> the impl's positional arg, captures the eval-safe
# KEY=VALUE stdout under RECORD_STORE, and always creates its output (graceful degradation).
set -uo pipefail
: "${USECASE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/deploy-defaults.env"
# Always (re)create $OUT so the contract's output_exists holds even if the impl errors.
: > "$OUT"
bash "$HERE/load_defaults.impl.sh" "${USECASE}" >> "$OUT" 2>>"$OUT.log" || true
[ -s "$OUT" ] || printf '# load_defaults produced no output for USECASE=%s (see %s.log)\n' "${USECASE}" "$OUT" > "$OUT"
printf '{"tool":"load_defaults","status":"ok","usecase":"%s","out":"%s"}\n' "${USECASE}" "$OUT"
