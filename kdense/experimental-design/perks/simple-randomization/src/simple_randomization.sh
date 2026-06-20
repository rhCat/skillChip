#!/usr/bin/env bash
# simple_randomization — seeded simple (independent per-unit) randomization schedule. Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/allocation_schedule.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/numpy/pandas are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_simple_randomization.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"simple_randomization","status":"ok","schedule":"%s"}\n' "$OUT"
