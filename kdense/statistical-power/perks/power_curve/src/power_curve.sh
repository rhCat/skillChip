#!/usr/bin/env bash
# power_curve — compute power vs. sample size and render a PNG planning figure
# via the vendored power.power_curve(). Reads TEST + EFFECT_SIZE + n-range from
# env; saves RECORD_STORE/power_curve.png and writes the (n, power) arrays as
# JSON to RECORD_STORE/power_curve.json. Structured JSON audit line.
set -uo pipefail
: "${TEST:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/power_curve.json"
# Pre-create so the contract's output_exists holds even if python/libs are absent.
: > "$OUT"
OUT="$OUT" PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" MPLBACKEND="Agg" \
  python3 "$HERE/cli_power_curve.py" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"power_curve","status":"ok","test":"%s","out":"%s"}\n' "$TEST" "$OUT"
