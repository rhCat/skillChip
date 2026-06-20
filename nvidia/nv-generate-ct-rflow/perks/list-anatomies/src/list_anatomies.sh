#!/usr/bin/env bash
# list_anatomies — localized from NVIDIA/skills nv-generate-ct-rflow (Apache-2.0). Structured-JSON audit line.
# Thin porter: env vars -> list_anatomies.py CLI. Reads $NV_GENERATE_ROOT/configs/label_dict.json and
# prints the NV-Generate-CTMR anatomy catalog grouped by body region (offline, deterministic, no GPU).
# The python helper writes the catalog to stdout; we capture that as catalog.txt under RECORD_STORE.
set -uo pipefail
: "${NV_GENERATE_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/catalog.txt"
: > "$OUT"
# list_anatomies.py reads NV_GENERATE_ROOT from the environment. Optional filters: REGION, FILTER,
# CONTROLLABLE (set to 1 to show only the 10 controllable anatomies). Translate env -> CLI flags.
export NV_GENERATE_ROOT
ARGS=()
[ -n "${REGION:-}" ] && ARGS+=(--region "${REGION}")
[ -n "${FILTER:-}" ] && ARGS+=(--filter "${FILTER}")
[ "${CONTROLLABLE:-}" = "1" ] && ARGS+=(--controllable)
python3 "$HERE/list_anatomies.py" "${ARGS[@]}" >"$OUT" 2>>"$OUT.log" || true
# Graceful degradation: always leave a non-empty catalog.txt even if label_dict was unreadable.
[ -s "$OUT" ] || printf '# nv-generate-ct-rflow anatomy catalog unavailable (NV_GENERATE_ROOT/configs/label_dict.json missing)\n' > "$OUT"
printf '{"tool":"list_anatomies","status":"ok","out":"%s"}\n' "$OUT"
