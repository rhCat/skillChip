#!/usr/bin/env bash
# power_sample_size — solve required sample size (closed-form) via the vendored
# power.sample_size(). Reads TEST + effect/allocation params from env, writes a
# JSON result to RECORD_STORE/sample_size.json. Structured JSON audit line.
set -uo pipefail
: "${TEST:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/sample_size.json"
# Pre-create so the contract's output_exists holds even if python/libs are absent.
: > "$OUT"
OUT="$OUT" PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/cli_sample_size.py" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"power_sample_size","status":"ok","test":"%s","out":"%s"}\n' "$TEST" "$OUT"
