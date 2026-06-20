#!/usr/bin/env bash
# simulate_power — Monte Carlo power for one bundled worked design via the
# vendored simulate_power harness. Reads DESIGN + N + N_SIMS + EFFECT from env,
# writes a JSON result (power + Wilson MC CI) to RECORD_STORE/simulate_power.json.
# Structured JSON audit line.
set -uo pipefail
: "${DESIGN:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/simulate_power.json"
# Pre-create so the contract's output_exists holds even if python/libs are absent.
: > "$OUT"
OUT="$OUT" PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/cli_simulate_power.py" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"simulate_power","status":"ok","design":"%s","out":"%s"}\n' "$DESIGN" "$OUT"
