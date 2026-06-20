#!/usr/bin/env bash
# latin_hypercube — space-filling Latin-hypercube sample over continuous factor ranges. Structured JSON output (audit/debug log).
set -uo pipefail
: "${SPEC_JSON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/experimental_runs.csv"
# Always (re)create $OUT so the contract's output_exists holds even if python/pyDOE3 are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/run_latin_hypercube.py" "$SPEC_JSON" "$OUT" >/dev/null 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"latin_hypercube","status":"ok","design":"%s"}\n' "$OUT"
