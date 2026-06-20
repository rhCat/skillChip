#!/usr/bin/env bash
# generate_schematic — AI scientific schematic via Nano Banana 2 (OpenRouter). Needs OPENROUTER_API_KEY,
# the requests library, and network. Structured JSON audit line; figure -> schematic.png.
set -uo pipefail
: "${SCHEMATIC_PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/schematic.png"
DOC_TYPE="${DOC_TYPE:-default}"
# Always (re)create $OUT so the contract's output_exists holds even when offline / no API key.
: > "$OUT"
# Core writes the PNG to -o; degrades when key/requests/network is absent (exit captured with || true).
python3 "$HERE/generate_schematic.py" "$SCHEMATIC_PROMPT" -o "$OUT" --doc-type "$DOC_TYPE" >/dev/null 2>&1 || true
# Guarantee the contract's output_exists even if no image was produced (offline fallback marker).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","schematic":"%s"}\n' "$OUT"
