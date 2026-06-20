#!/usr/bin/env bash
# gen_schematic — AI scientific-schematic generation for hypothesis reports.
# Thin porter over the vendored K-Dense cores generate_schematic.py -> generate_schematic_ai.py.
# Reads SCHEMATIC_PROMPT (+ optional DOC_TYPE, ITERATIONS, OPENROUTER_API_KEY) from env,
# translates to CLI args, and writes all artifacts under RECORD_STORE. Emits one audit JSON line.
set -uo pipefail
: "${SCHEMATIC_PROMPT:?}" "${RECORD_STORE:?}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE="${RECORD_STORE%/}"
mkdir -p "$STORE" 2>/dev/null || true

DOC_TYPE="${DOC_TYPE:-default}"
ITERATIONS="${ITERATIONS:-2}"
IMG="${STORE}/schematic.png"
OUT="${STORE}/schematic.json"

# Always (re)create the audit artifact so the contract's output_exists holds
# even if python/requests/network/API key are absent or the core errors.
: > "$OUT"

STATUS="ok"
NOTE="generated"

if ! command -v python3 >/dev/null 2>&1; then
  STATUS="skipped"
  NOTE="python3 not found on PATH"
elif ! python3 -c "import requests" >/dev/null 2>&1; then
  STATUS="skipped"
  NOTE="requests library not installed"
elif [ -z "${OPENROUTER_API_KEY:-}" ]; then
  STATUS="skipped"
  NOTE="OPENROUTER_API_KEY not set; network generation unavailable"
else
  python3 "${HERE}/generate_schematic.py" \
    "$SCHEMATIC_PROMPT" \
    -o "$IMG" \
    --doc-type "$DOC_TYPE" \
    --iterations "$ITERATIONS" \
    > "${STORE}/schematic.stdout.log" 2>&1 || true
  if [ ! -s "$IMG" ]; then
    STATUS="degraded"
    NOTE="core ran but produced no image (see schematic.stdout.log)"
  fi
fi

# The core writes <stem>_review_log.json next to the image; surface it under a stable name.
if [ -s "${STORE}/schematic_review_log.json" ]; then
  REVIEW="${STORE}/schematic_review_log.json"
else
  REVIEW=""
fi

printf '{"tool":"gen_schematic","status":"%s","note":"%s","image":"%s","review_log":"%s","doc_type":"%s","iterations":"%s"}\n' \
  "$STATUS" "$NOTE" "$IMG" "$REVIEW" "$DOC_TYPE" "$ITERATIONS" > "$OUT"

[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
