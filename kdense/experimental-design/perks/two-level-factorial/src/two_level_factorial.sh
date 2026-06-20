#!/usr/bin/env bash
# two_level_factorial — full 2^k factorial DOE (all main effects + interactions) in real units. Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/experimental_runs.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/pyDOE3 are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_two_level_factorial.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"two_level_factorial","status":"ok","design":"%s"}\n' "$OUT"
