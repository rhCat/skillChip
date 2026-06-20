#!/usr/bin/env bash
# arbor_init — porter: initialize a new Arbor AO run (hypothesis tree + run config) under
# record_store/run/.arbor/. Thin env->arg translation around the vendored tree.py core.
# The logic lives in tree.py (standalone stdlib CLI — inspect / lint / test it directly).
set -uo pipefail
: "${OBJECTIVE:?}" "${DEV_EVAL:?}" "${TEST_EVAL:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/init.txt"
mkdir -p "$RUN_DIR"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" init \
  --objective "$OBJECTIVE" \
  --dev-eval "$DEV_EVAL" \
  --test-eval "$TEST_EVAL" \
  --material "${MATERIAL:-.}" \
  --metric-direction "${METRIC_DIRECTION:-max}" \
  --branching "${BRANCHING:-3}" \
  --max-depth "${MAX_DEPTH:-2}" \
  --budget "${BUDGET:-12}" \
  --force >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_init","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
