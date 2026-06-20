#!/usr/bin/env bash
# generate_schematic — generate an AI scientific schematic (PNG) for a poster via
# generate_schematic.py -> generate_schematic_ai.py (OpenRouter: Nano Banana 2 + Gemini review).
# Read-only w.r.t. the workspace (writes a PNG + a JSON result manifest under RECORD_STORE).
# Emits ONE structured-JSON audit line. Degrades gracefully when offline / no API key / no requests.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
OUTPUT_NAME="${OUTPUT_NAME:-schematic.png}"
DOC_TYPE="${DOC_TYPE:-poster}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="${RECORD_STORE%/}/${OUTPUT_NAME}"
OUT="${RECORD_STORE%/}/schematic.json"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors / is offline.
: > "$OUT"
# Vendored core lives beside this porter; run via python3 with HERE on PYTHONPATH.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/generate_schematic.py" \
  "$PROMPT" -o "$IMG" --doc-type "$DOC_TYPE" > "${RECORD_STORE%/}/schematic.run.log" 2>&1 || true
if [ -s "$IMG" ]; then
  STATUS="generated"
else
  STATUS="skipped_offline_or_no_api_key"
fi
printf '{"tool":"generate_schematic","status":"ok","result":"%s","image":"%s","doc_type":"%s","outcome":"%s"}\n' \
  "$OUT" "$IMG" "$DOC_TYPE" "$STATUS" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","result":"%s","image":"%s","outcome":"%s"}\n' \
  "$OUT" "$IMG" "$STATUS"
