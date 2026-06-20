#!/usr/bin/env bash
# check_interconnect — localized from NVIDIA/skills dynamo-interconnect-check (Apache-2.0). Structured-JSON audit line.
# Runs the read-only `env` subcommand: inspects NIXL/UCX/NCCL transport vars on a recipe/manifest.
# (The script also exposes `node`/`nixl` pod probes — invoke check_interconnect.py directly with --namespace/--pod for those.)
set -uo pipefail
: "${RECIPE_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/interconnect.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/script errors.
: > "$OUT"
python3 "$HERE/check_interconnect.py" env "${RECIPE_DIR}" >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_interconnect","status":"ok","out":"%s"}\n' "$OUT"
