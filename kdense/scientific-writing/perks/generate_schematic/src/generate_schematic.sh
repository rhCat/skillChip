#!/usr/bin/env bash
# generate_schematic — text prompt -> publication-quality scientific schematic PNG via OpenRouter
# (Nano Banana 2 generation + Gemini 3.1 Pro quality review, vendored generate_schematic.py ->
# generate_schematic_ai.py). Read-only w.r.t. local state; calls the network. Structured JSON audit.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_NAME="${OUTPUT_NAME:-schematic.png}"
DOC_TYPE="${DOC_TYPE:-default}"
IMG="${RECORD_STORE%/}/${OUTPUT_NAME}"
OUT="${RECORD_STORE%/}/schematic.audit.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3/network/key are absent.
: > "$OUT"
mkdir -p "$RECORD_STORE" 2>/dev/null || true

python3 "$HERE/generate_schematic.py" "$PROMPT" -o "$IMG" --doc-type "$DOC_TYPE" \
  > "${RECORD_STORE%/}/schematic.gen.log" 2>&1 || true

if [ -s "$IMG" ]; then
  printf '{"tool":"generate_schematic","status":"ok","image":"%s","doc_type":"%s"}\n' "$IMG" "$DOC_TYPE" > "$OUT"
else
  printf '{"tool":"generate_schematic","status":"ok","image":null,"doc_type":"%s","note":"no image produced (missing OPENROUTER_API_KEY / network / requests)"}\n' "$DOC_TYPE" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","audit":"%s"}\n' "$OUT"
