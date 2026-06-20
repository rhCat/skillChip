#!/usr/bin/env bash
# generate_schematic — AI-generate a publication-quality scientific schematic (CONSORT flow, timeline, etc.).
# Requires OPENROUTER_API_KEY + the `requests` library + network; degrades gracefully when absent.
set -uo pipefail
: "${SCHEMATIC_PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_TYPE="${DOC_TYPE:-default}"
IMG="${RECORD_STORE%/}/schematic.png"
OUT="${RECORD_STORE%/}/schematic.json"
mkdir -p "${RECORD_STORE%/}"
# Always (re)create the audit artifact so the contract's output_exists holds even offline.
: > "$OUT"
status="ok"
if [ -z "${OPENROUTER_API_KEY:-}" ]; then
  status="skipped_no_api_key"
else
  # The wrapper shells out to the sibling generate_schematic_ai.py (vendored alongside in src/).
  python3 "$HERE/generate_schematic.py" "$SCHEMATIC_PROMPT" -o "$IMG" --doc-type "$DOC_TYPE" >/dev/null 2>&1 || status="generation_failed"
fi
printf '{"tool":"generate_schematic","status":"%s","prompt":"%s","doc_type":"%s","image":"%s"}\n' \
  "$status" "$SCHEMATIC_PROMPT" "$DOC_TYPE" "$IMG" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"%s","report":"%s"}\n' "$status" "$OUT"
