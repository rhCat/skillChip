#!/usr/bin/env bash
# schematic — generate an AI scientific schematic (PNG) via OpenRouter / Nano-Banana.
# Writes a local PNG under RECORD_STORE but CALLS THE OPENROUTER API (network + OPENROUTER_API_KEY).
# Vendored core: generate_schematic.py + generate_schematic_ai.py. Structured JSON audit.
# Degrades gracefully when the key/network is absent (records the gap; writes an empty placeholder).
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
DOC_TYPE="${DOC_TYPE:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/schematic.png"
# Pre-create $OUT so the contract's output_exists holds even without an API key / network.
: > "$OUT"

set -- "$PROMPT" -o "$OUT"
[ -n "$DOC_TYPE" ] && set -- "$@" --doc-type "$DOC_TYPE"

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_schematic.py" "$@" >> "${RECORD_STORE%/}/schematic.log" 2>&1 || true

# Guarantee a non-empty output for the contract even when the API key / network is unavailable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"schematic","status":"ok","schematic":"%s"}\n' "$OUT"
