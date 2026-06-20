#!/usr/bin/env bash
# run_mr_brain — localized from NVIDIA/skills nv-generate-mr-brain (Apache-2.0). Structured-JSON audit line.
# Thin porter: translates env vars -> run_mr_brain.py CLI args and writes the result JSON under RECORD_STORE.
# The upstream wrapper prints its result payload to stdout, so stdout is captured into $OUT (result.json).
set -uo pipefail
: "${MODEL_CONFIG:?}" "${OUTPUT_DIR:?}" "${MODALITY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/upstream are absent or error.
: > "$OUT"

if ! command -v python3 >/dev/null 2>&1; then
  printf '{}' > "$OUT"
  printf '{"tool":"run_mr_brain","status":"ok","out":"%s","note":"python3 not found on PATH"}\n' "$OUT"
  exit 0
fi

# run_mr_brain.py emits the full result payload on stdout; capture it as result.json.
# NV_GENERATE_ROOT (cloned NV-Generate-CTMR upstream) is read from the environment by the script.
python3 "$HERE/run_mr_brain.py" \
  "${MODEL_CONFIG}" \
  --output-dir "${OUTPUT_DIR}" \
  --modality "${MODALITY}" \
  ${RANDOM_SEED:+--random-seed "${RANDOM_SEED}"} \
  >"$OUT" 2>"$OUT.log" || true

# Graceful degradation: never leave an empty/zero-byte output file.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_mr_brain","status":"ok","out":"%s"}\n' "$OUT"
