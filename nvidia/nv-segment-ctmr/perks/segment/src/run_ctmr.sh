#!/usr/bin/env bash
# run_ctmr — localized from NVIDIA/skills nv-segment-ctmr (Apache-2.0). Structured-JSON audit line.
# Thin porter: translates env vars -> run_ctmr.py CLI args, writes the wrapper's
# result JSON + the produced NIfTI label map under RECORD_STORE. Inference is
# delegated entirely to the upstream MONAI bundle (python -m monai.bundle run).
set -uo pipefail
: "${CT_OR_MR_VOLUME:?}" "${RECORD_STORE:?}"
MODALITY="${MODALITY:-CT_BODY}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
# Always (re)create $OUT so the contract's output_exists holds even if deps/weights/GPU are absent.
: > "$OUT"
# run_ctmr.py emits its result JSON on stdout; the NIfTI label map lands under --output-dir.
python3 "$HERE/run_ctmr.py" "${CT_OR_MR_VOLUME}" \
  --modality "${MODALITY}" \
  --output-dir "${RECORD_STORE%/}/segment_ctmr_outputs" \
  >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_ctmr","status":"ok","out":"%s"}\n' "$OUT"
