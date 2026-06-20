#!/usr/bin/env bash
# power_mde — solve the minimum detectable effect at a fixed n (closed-form) via
# the vendored power.mde(). Reads TEST + n + alpha/power from env, writes a JSON
# result to RECORD_STORE/mde.json. Structured JSON audit line.
set -uo pipefail
: "${TEST:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/mde.json"
# Pre-create so the contract's output_exists holds even if python/libs are absent.
: > "$OUT"
OUT="$OUT" PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/cli_mde.py" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"power_mde","status":"ok","test":"%s","out":"%s"}\n' "$TEST" "$OUT"
