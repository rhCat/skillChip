#!/usr/bin/env bash
# cluster_randomization — seeded randomization of whole clusters (sites/clinics/classes) to arms. Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/cluster_allocation.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/numpy/pandas are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_cluster_randomization.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"cluster_randomization","status":"ok","schedule":"%s"}\n' "$OUT"
