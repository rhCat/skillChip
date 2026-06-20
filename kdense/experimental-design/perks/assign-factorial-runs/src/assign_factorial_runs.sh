#!/usr/bin/env bash
# assign_factorial_runs — randomize the execution run order of a set of design rows (defeat drift). Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/run_order.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/numpy/pandas are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_assign_factorial_runs.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"assign_factorial_runs","status":"ok","run_order":"%s"}\n' "$OUT"
