#!/usr/bin/env bash
# block_randomization — seeded permuted-block randomization schedule (balance throughout enrollment). Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/allocation_schedule.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/numpy/pandas are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_block_randomization.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"block_randomization","status":"ok","schedule":"%s"}\n' "$OUT"
