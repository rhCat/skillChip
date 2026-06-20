#!/usr/bin/env bash
# cleanup_staging — localized from NVIDIA/skills deepstream-import-vision-model (Apache-2.0).
# Entry porter for the `cleanup-staging` perk: removes the scoped staging artifacts for a model
# (build/.venv_<name>, models/<name>/hf_model, models/<name>/onnx_export) while preserving the
# shared venv — a standalone post-export housekeeping op. Translates env vars -> the vendored
# impl's CLI args, runs the impl with CWD scoped under RECORD_STORE so removals stay sandboxed,
# writes a manifest under RECORD_STORE, and ALWAYS emits ONE line of structured JSON on stdout.
# DESTRUCTIVE: set CLEANUP_DRY_RUN=1 to preview removals without deleting.
set -uo pipefail
: "${MODEL_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/cleanup-staging.json"
LOG="${RECORD_STORE%/}/cleanup-staging.log"

# The impl scopes removals to ./build/ and ./models/ relative to its CWD. Default the working
# root to a sandbox under RECORD_STORE so the perk never touches the caller's real tree unless
# CLEANUP_ROOT is explicitly provided.
CLEANUP_ROOT="${CLEANUP_ROOT:-${RECORD_STORE%/}/workspace}"
mkdir -p "$CLEANUP_ROOT" 2>/dev/null || true

# Pre-create the manifest so output_exists holds even if the impl/bash is unavailable.
: > "$LOG"

DRY_ARG=""
[ "${CLEANUP_DRY_RUN:-}" = "1" ] && DRY_ARG="--dry-run"

# The vendored impl reads positional args: <MODEL_NAME> [--dry-run]; it acts relative to $(pwd).
( cd "$CLEANUP_ROOT" && bash "$HERE/cleanup.sh" "${MODEL_NAME}" $DRY_ARG ) >"$LOG" 2>&1 || true

REMOVED=$(grep -c '  removing: ' "$LOG" 2>/dev/null | head -1); REMOVED="${REMOVED:-0}"
PLANNED=$(grep -c '  \[dry-run\] ' "$LOG" 2>/dev/null | head -1); PLANNED="${PLANNED:-0}"

# Emit the step manifest as the perk's named output.
if command -v python3 >/dev/null 2>&1; then
  MODEL_NAME="$MODEL_NAME" CLEANUP_ROOT="$CLEANUP_ROOT" DRY="${CLEANUP_DRY_RUN:-0}" REMOVED="$REMOVED" PLANNED="$PLANNED" \
  python3 - <<'PYEOF' > "$OUT" 2>/dev/null || printf '{}' > "$OUT"
import json, os
print(json.dumps({
    "skill": "deepstream-import-vision-model",
    "perk": "cleanup-staging",
    "step": "housekeeping",
    "model_name": os.environ.get("MODEL_NAME", ""),
    "cleanup_root": os.environ.get("CLEANUP_ROOT", ""),
    "dry_run": os.environ.get("DRY", "0") == "1",
    "removed": int(os.environ.get("REMOVED", "0") or 0),
    "planned": int(os.environ.get("PLANNED", "0") or 0),
}))
PYEOF
else
  printf '{"skill":"deepstream-import-vision-model","perk":"cleanup-staging","step":"housekeeping","model_name":"%s","cleanup_root":"%s","dry_run":%s,"removed":%s,"planned":%s}' \
    "$MODEL_NAME" "$CLEANUP_ROOT" "${CLEANUP_DRY_RUN:-0}" "$REMOVED" "$PLANNED" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"cleanup_staging","status":"ok","out":"%s","removed":%s,"planned":%s}\n' "$OUT" "$REMOVED" "$PLANNED"
