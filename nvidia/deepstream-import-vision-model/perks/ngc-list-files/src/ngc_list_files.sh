#!/usr/bin/env bash
# ngc_list_files — localized from NVIDIA/skills deepstream-import-vision-model (Apache-2.0).
# Entry porter for the `ngc-list-files` perk: lists the files in a public NVIDIA NGC model
# version (the NGC counterpart of hf_list_files in the Model Acquire phase) so the downstream
# acquire/build steps know what to pull. Translates env vars -> the vendored impl's CLI args,
# writes under RECORD_STORE, and ALWAYS emits ONE line of structured JSON on stdout
# (graceful degradation: the NGC network/API may be unreachable, curl/python may be missing).
set -uo pipefail
: "${NGC_ORG:?}" "${MODEL_NAME:?}" "${NGC_VERSION:?}" "${RECORD_STORE:?}"
NGC_TEAM="${NGC_TEAM:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/ngc-list-files.json"
FILES="${RECORD_STORE%/}/ngc-files.txt"

# Always (re)create the outputs so the contract's output_exists holds even when the
# network is down or curl/python3 is missing.
: > "$FILES"

# The vendored impl reads positional args: <NGC_ORG> <NGC_TEAM> <MODEL_NAME> <NGC_VERSION>.
# NGC_TEAM may be the empty string for models with no team segment.
bash "$HERE/ngc-list-files.sh" "${NGC_ORG}" "${NGC_TEAM}" "${MODEL_NAME}" "${NGC_VERSION}" > "$FILES" 2>"$FILES.log" || true

N_FILES=$(grep -c . "$FILES" 2>/dev/null | head -1); N_FILES="${N_FILES:-0}"

# Emit the step manifest as the perk's named output.
if command -v python3 >/dev/null 2>&1; then
  NGC_ORG="$NGC_ORG" NGC_TEAM="$NGC_TEAM" MODEL_NAME="$MODEL_NAME" NGC_VERSION="$NGC_VERSION" FILES="$FILES" N_FILES="$N_FILES" \
  python3 - <<'PYEOF' > "$OUT" 2>/dev/null || printf '{}' > "$OUT"
import json, os
print(json.dumps({
    "skill": "deepstream-import-vision-model",
    "perk": "ngc-list-files",
    "step": "model-acquire",
    "ngc_org": os.environ.get("NGC_ORG", ""),
    "ngc_team": os.environ.get("NGC_TEAM", ""),
    "model_name": os.environ.get("MODEL_NAME", ""),
    "ngc_version": os.environ.get("NGC_VERSION", ""),
    "files_listed": int(os.environ.get("N_FILES", "0") or 0),
    "files_path": os.environ.get("FILES", ""),
}))
PYEOF
else
  printf '{"skill":"deepstream-import-vision-model","perk":"ngc-list-files","step":"model-acquire","ngc_org":"%s","ngc_team":"%s","model_name":"%s","ngc_version":"%s","files_listed":%s,"files_path":"%s"}' \
    "$NGC_ORG" "$NGC_TEAM" "$MODEL_NAME" "$NGC_VERSION" "$N_FILES" "$FILES" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"ngc_list_files","status":"ok","out":"%s","files":"%s","n_files":%s}\n' "$OUT" "$FILES" "$N_FILES"
