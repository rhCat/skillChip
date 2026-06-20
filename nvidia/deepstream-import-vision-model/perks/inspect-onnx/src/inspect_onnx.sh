#!/usr/bin/env bash
# inspect_onnx — localized from NVIDIA/skills deepstream-import-vision-model (Apache-2.0).
# Entry porter for the `inspect-onnx` perk: inspects an ONNX model file and reports its
# inputs/outputs/opset/operators/validity plus a machine-parseable H/W summary (the same
# data the engine-build phase greps). Translates env vars -> the vendored impl's CLI args,
# writes under RECORD_STORE, and ALWAYS emits ONE line of structured JSON on stdout
# (graceful degradation: the `onnx` python package may be absent / the file may be missing).
set -uo pipefail
: "${ONNX_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/inspect-onnx.json"
REPORT="${RECORD_STORE%/}/onnx-info.txt"

# Always (re)create the outputs so the contract's output_exists holds even when the
# `onnx` package is absent, the input file is missing, or python3 is unavailable.
: > "$REPORT"

# The vendored impl reads one positional arg: <onnx_file>. Capture human-readable info.
python3 "$HERE/inspect-onnx.py" "${ONNX_FILE}" > "$REPORT" 2>"$REPORT.log" || true

N_LINES=$(grep -c . "$REPORT" 2>/dev/null | head -1); N_LINES="${N_LINES:-0}"
VALID=false
grep -q "ONNX model is valid" "$REPORT" 2>/dev/null && VALID=true

# Emit the step manifest as the perk's named output.
if command -v python3 >/dev/null 2>&1; then
  ONNX_FILE="$ONNX_FILE" REPORT="$REPORT" N_LINES="$N_LINES" VALID="$VALID" \
  python3 - <<'PYEOF' > "$OUT" 2>/dev/null || printf '{}' > "$OUT"
import json, os
print(json.dumps({
    "skill": "deepstream-import-vision-model",
    "perk": "inspect-onnx",
    "step": "model-inspect",
    "onnx_file": os.environ.get("ONNX_FILE", ""),
    "report_path": os.environ.get("REPORT", ""),
    "report_lines": int(os.environ.get("N_LINES", "0") or 0),
    "valid": os.environ.get("VALID", "false") == "true",
}))
PYEOF
else
  printf '{"skill":"deepstream-import-vision-model","perk":"inspect-onnx","step":"model-inspect","onnx_file":"%s","report_path":"%s","report_lines":%s,"valid":%s}' \
    "$ONNX_FILE" "$REPORT" "$N_LINES" "$VALID" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"inspect_onnx","status":"ok","out":"%s","report":"%s","report_lines":%s,"valid":%s}\n' "$OUT" "$REPORT" "$N_LINES" "$VALID"
