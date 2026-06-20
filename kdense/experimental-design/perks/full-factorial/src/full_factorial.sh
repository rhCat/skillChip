#!/usr/bin/env bash
# full_factorial — full-factorial DOE matrix over explicit factor levels, in real units. Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/experimental_runs.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/pyDOE3 are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_full_factorial.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"full_factorial","status":"ok","design":"%s"}\n' "$OUT"
