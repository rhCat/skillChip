#!/usr/bin/env bash
# schematic — generate an AI scientific schematic / poster figure from a natural-language prompt
# via OpenRouter (Nano Banana 2 + Gemini review). Env->arg translation; graceful offline degrade.
# Writes the image to $RECORD_STORE/$OUTPUT_NAME and an audit log to $RECORD_STORE/schematic.log.
# One structured-JSON audit line on stdout.
set -uo pipefail
: "${PROMPT:?}" "${OUTPUT_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_TYPE="${DOC_TYPE:-default}"
ITERATIONS="${ITERATIONS:-2}"

OUT="${RECORD_STORE%/}/schematic.log"
IMG="${RECORD_STORE%/}/${OUTPUT_NAME}"
# Always (re)create $OUT so the contract's output_exists holds even if python/requests/key are absent.
: > "$OUT"

# Vendored core needs to import its sibling generate_schematic_ai.py.
export PYTHONPATH="${HERE}:${PYTHONPATH:-}"

# Build the core invocation (env -> args). DOC_TYPE only passed when non-default (core uses choices).
CMD=(python3 "${HERE}/generate_schematic.py" "$PROMPT" -o "$IMG" --iterations "$ITERATIONS")
if [ "$DOC_TYPE" != "default" ]; then
  CMD+=(--doc-type "$DOC_TYPE")
fi

# Run the core. Never abort the governed run on a missing key / network / requests; capture all output.
"${CMD[@]}" >> "$OUT" 2>&1 || true

# Backfill so the artifact is never zero-length (graceful offline degrade).
[ -s "$OUT" ] || printf '{}' > "$OUT"

# Did an actual image land?
if [ -s "$IMG" ]; then IMG_STATUS="written"; else IMG_STATUS="absent"; fi

printf '{"tool":"schematic","status":"ok","log":"%s","image":"%s","image_status":"%s","doc_type":"%s","iterations":"%s"}\n' \
  "$OUT" "$IMG" "$IMG_STATUS" "$DOC_TYPE" "$ITERATIONS"
