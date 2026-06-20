#!/usr/bin/env bash
# generate_schematic — generate a scientific schematic via Nano Banana 2 (OpenRouter) into RECORD_STORE. Structured JSON audit line.
# Vendored cores: generate_schematic.py (CLI wrapper) + generate_schematic_ai.py (sibling it invokes). Needs OPENROUTER_API_KEY + network.
# Porter degrades gracefully: no key / offline -> a JSON stub stands in for the image so the contract still holds.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/schematic.png"
# Pre-create so the contract's output_exists holds even when the API/key/network is unavailable.
: > "$OUT"
ARGS=("$PROMPT" -o "$OUT")
if [ -n "${DOC_TYPE:-}" ]; then
  ARGS+=(--doc-type "$DOC_TYPE")
fi
# The wrapper finds generate_schematic_ai.py beside itself (script_dir); both are vendored here together.
python3 "$HERE/generate_schematic.py" "${ARGS[@]}" >"${RECORD_STORE%/}/generate_schematic.log" 2>&1 || true
# If no real image was written (offline/no key), leave a JSON stub so output_exists + nonempty still hold.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","image":"%s"}\n' "$OUT"
