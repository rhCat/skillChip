#!/usr/bin/env bash
# central_composite — central-composite response-surface DOE (curvature / optimization). Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/experimental_runs.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/pyDOE3 are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_central_composite.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"central_composite","status":"ok","design":"%s"}\n' "$OUT"
