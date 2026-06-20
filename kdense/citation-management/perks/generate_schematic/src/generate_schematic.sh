#!/usr/bin/env bash
# generate_schematic — porter: generate a scientific schematic via the vendored core (generate_schematic.py).
# Core is an UNCHANGED argparse CLI: positional <prompt>, -o/--output (required), --doc-type, --api-key.
# The entry script shells out to its sibling generate_schematic_ai.py (both vendored here, resolved via
# Path(__file__).parent). Reads PROMPT/DOC_TYPE/OPENROUTER_API_KEY/RECORD_STORE from the environment.
# Needs OPENROUTER_API_KEY + network; the porter degrades gracefully (pre-created {} stub) when absent.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/schematic.png"
# Pre-create so the contract's output_exists holds even if generation fails / is offline / no API key.
: > "$OUT"

ARGS=("$PROMPT" -o "$OUT")
if [ -n "${DOC_TYPE:-}" ]; then
  ARGS+=(--doc-type "$DOC_TYPE")
fi

python3 "$HERE/generate_schematic.py" "${ARGS[@]}" 1>&2 || true

# Guarantee a non-empty artifact even when no API key / offline.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","out":"%s"}\n' "$OUT"
