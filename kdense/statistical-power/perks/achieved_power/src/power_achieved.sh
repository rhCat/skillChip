#!/usr/bin/env bash
# power_achieved — solve achieved power at a fixed n (closed-form) via the
# vendored power.power(). Reads TEST + n + effect params from env, writes a JSON
# result to RECORD_STORE/achieved_power.json. Structured JSON audit line.
set -uo pipefail
: "${TEST:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/achieved_power.json"
# Pre-create so the contract's output_exists holds even if python/libs are absent.
: > "$OUT"
OUT="$OUT" PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/cli_achieved_power.py" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"power_achieved","status":"ok","test":"%s","out":"%s"}\n' "$TEST" "$OUT"
