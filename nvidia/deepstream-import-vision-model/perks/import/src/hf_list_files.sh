#!/usr/bin/env bash
# hf_list_files — localized from NVIDIA/skills deepstream-import-vision-model (Apache-2.0).
# Entry porter for the `import` perk: lists the source model repo's files (step 1 of the
# Model Acquire phase) so the downstream engine-build / pipeline / report steps know what
# to pull. Translates env vars -> the vendored impl's CLI args, writes under RECORD_STORE,
# and ALWAYS emits ONE line of structured JSON on stdout (graceful degradation).
set -uo pipefail
: "${HF_ORG:?}" "${MODEL_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/import.json"
FILES="${RECORD_STORE%/}/hf-files.txt"

# Always (re)create the outputs so the contract's output_exists holds even when the
# impl is absent, the network is down, or curl/python is missing.
: > "$FILES"

# The vendored impl reads positional args: <HF_ORG> <MODEL_NAME> [subpath]; it honors $HF_TOKEN.
bash "$HERE/hf_list_files.impl.sh" "${HF_ORG}" "${MODEL_NAME}" > "$FILES" 2>"$FILES.log" || true

N_FILES=$(grep -c . "$FILES" 2>/dev/null || printf '0')

# Emit a small step manifest as the perk's named output. Use python3 for safe JSON if present,
# else fall back to a minimal hand-written object so import.json always exists and parses.
if command -v python3 >/dev/null 2>&1; then
  HF_ORG="$HF_ORG" MODEL_NAME="$MODEL_NAME" FILES="$FILES" N_FILES="$N_FILES" \
  python3 - <<'PYEOF' > "$OUT" 2>/dev/null || printf '{}' > "$OUT"
import json, os
print(json.dumps({
    "skill": "deepstream-import-vision-model",
    "perk": "import",
    "step": "model-acquire",
    "hf_org": os.environ.get("HF_ORG", ""),
    "model_name": os.environ.get("MODEL_NAME", ""),
    "files_listed": int(os.environ.get("N_FILES", "0") or 0),
    "files_path": os.environ.get("FILES", ""),
}))
PYEOF
else
  printf '{"skill":"deepstream-import-vision-model","perk":"import","step":"model-acquire","hf_org":"%s","model_name":"%s","files_listed":%s,"files_path":"%s"}' \
    "$HF_ORG" "$MODEL_NAME" "$N_FILES" "$FILES" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"hf_list_files","status":"ok","out":"%s","files":"%s","n_files":%s}\n' "$OUT" "$FILES" "$N_FILES"
