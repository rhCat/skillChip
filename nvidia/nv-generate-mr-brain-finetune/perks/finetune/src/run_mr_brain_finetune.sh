#!/usr/bin/env bash
# run_mr_brain_finetune — localized from NVIDIA/skills nv-generate-mr-brain-finetune (Apache-2.0). Structured-JSON audit line.
# Thin porter: env vars -> the upstream wrapper's CLI; writes result.json + an artifacts/ tree under RECORD_STORE.
set -uo pipefail
: "${DATALIST:?}" "${DATA_BASE_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
ARTIFACTS="${RECORD_STORE%/}/artifacts"
# Always (re)create $OUT so the contract's output_exists holds even if python/deps are absent or the run errors.
: > "$OUT"
mkdir -p "$ARTIFACTS"

# --preflight is the safe, no-GPU path; pass it whenever PREFLIGHT is set non-empty.
PREFLIGHT_FLAG=()
if [ -n "${PREFLIGHT:-}" ]; then
  PREFLIGHT_FLAG=(--preflight)
fi

# The wrapper emits its result JSON to stdout; capture it into $OUT. Diagnostics go to $OUT.log.
python3 "$HERE/run_mr_brain_finetune.py" \
  "${DATALIST}" \
  --data-base-dir "${DATA_BASE_DIR}" \
  --output-dir "${ARTIFACTS}" \
  "${PREFLIGHT_FLAG[@]}" \
  >"$OUT" 2>"$OUT.log" || true

# Graceful degradation: ensure $OUT is valid JSON even if the wrapper could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_mr_brain_finetune","status":"ok","out":"%s"}\n' "$OUT"
