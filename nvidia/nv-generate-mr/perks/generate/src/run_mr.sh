#!/usr/bin/env bash
# run_mr — localized from NVIDIA/skills nv-generate-mr (Apache-2.0). Structured-JSON audit line.
# Thin porter: translates env vars -> run_mr.py's CLI and writes outputs under RECORD_STORE.
# run_mr.py emits its result summary to stdout, so stdout is captured into result.json.
set -uo pipefail
: "${MODEL_CONFIG:?}" "${MODALITY:?}" "${RANDOM_SEED:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/deps/GPU are absent.
: > "$OUT"
python3 "$HERE/run_mr.py" \
  "${MODEL_CONFIG}" \
  --output-dir "${RECORD_STORE%/}/samples" \
  --modality "${MODALITY}" \
  --random-seed "${RANDOM_SEED}" \
  >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_mr","status":"ok","out":"%s"}\n' "$OUT"
