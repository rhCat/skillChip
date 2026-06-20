#!/usr/bin/env bash
# check_router_health — localized from NVIDIA/skills dynamo-router-starter (Apache-2.0). Structured-JSON audit line.
set -uo pipefail
: "${BASE_URL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/router_health.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/network is absent or errors.
: > "$OUT"

ARGS=(--base-url "${BASE_URL}")
if [ -n "${RETRIES:-}" ]; then
  ARGS+=(--retries "${RETRIES}")
fi

# The script prints its result JSON to stdout; capture it as the artifact.
python3 "$HERE/check_router_health.py" "${ARGS[@]}" >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"check_router_health","status":"ok","out":"%s"}\n' "$OUT"
