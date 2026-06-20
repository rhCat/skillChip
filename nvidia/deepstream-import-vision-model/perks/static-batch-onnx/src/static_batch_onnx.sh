#!/usr/bin/env bash
# static_batch_onnx — localized from NVIDIA/skills deepstream-import-vision-model (Apache-2.0).
# Entry porter for the `static-batch-onnx` perk: bakes a fixed batch dimension into a batch-1
# ONNX model (patches input/output batch dims + internal Reshape nodes) producing a new static
# -batch ONNX (an Engine-Build prep step usable on its own). Translates env vars -> the vendored
# impl's CLI args, writes the result + manifest under RECORD_STORE, and ALWAYS emits ONE line of
# structured JSON on stdout (graceful degradation: `onnx`/`numpy` may be absent, input missing).
set -uo pipefail
: "${SRC_ONNX:?}" "${BATCH_SIZE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/static-batch-onnx.json"
DST="${DST_ONNX:-${RECORD_STORE%/}/model_b${BATCH_SIZE}.onnx}"

# Pre-create the manifest so output_exists holds even when onnx/numpy is absent or the
# input ONNX is missing/unparseable (the vendored impl writes DST only on success).
mkdir -p "$(dirname "$DST")" 2>/dev/null || true

# The vendored impl reads positional args: <src_onnx> <dst_onnx> <batch_size>.
LOG="${RECORD_STORE%/}/static-batch-onnx.log"
python3 "$HERE/make-static-batch-onnx.py" "${SRC_ONNX}" "${DST}" "${BATCH_SIZE}" >"$LOG" 2>&1 || true

WROTE=false
[ -s "$DST" ] && WROTE=true

# Emit the step manifest as the perk's named output.
if command -v python3 >/dev/null 2>&1; then
  SRC_ONNX="$SRC_ONNX" DST="$DST" BATCH_SIZE="$BATCH_SIZE" WROTE="$WROTE" \
  python3 - <<'PYEOF' > "$OUT" 2>/dev/null || printf '{}' > "$OUT"
import json, os
print(json.dumps({
    "skill": "deepstream-import-vision-model",
    "perk": "static-batch-onnx",
    "step": "engine-build-prep",
    "src_onnx": os.environ.get("SRC_ONNX", ""),
    "dst_onnx": os.environ.get("DST", ""),
    "batch_size": int(os.environ.get("BATCH_SIZE", "0") or 0),
    "wrote_output": os.environ.get("WROTE", "false") == "true",
}))
PYEOF
else
  printf '{"skill":"deepstream-import-vision-model","perk":"static-batch-onnx","step":"engine-build-prep","src_onnx":"%s","dst_onnx":"%s","batch_size":%s,"wrote_output":%s}' \
    "$SRC_ONNX" "$DST" "$BATCH_SIZE" "$WROTE" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"static_batch_onnx","status":"ok","out":"%s","dst_onnx":"%s","wrote_output":%s}\n' "$OUT" "$DST" "$WROTE"
