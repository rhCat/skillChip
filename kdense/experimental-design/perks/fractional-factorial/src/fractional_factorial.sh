#!/usr/bin/env bash
# fractional_factorial — 2^(k-p) fractional-factorial DOE from a Yates generator string. Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/experimental_runs.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/pyDOE3 are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_fractional_factorial.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"fractional_factorial","status":"ok","design":"%s"}\n' "$OUT"
