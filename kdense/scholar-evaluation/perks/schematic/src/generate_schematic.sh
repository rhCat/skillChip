#!/usr/bin/env bash
# generate_schematic — AI scientific-schematic generation via OpenRouter (Nano Banana 2) + Gemini review.
# Thin porter: env -> args for the vendored generate_schematic.py core (which calls generate_schematic_ai.py).
# Needs OPENROUTER_API_KEY + requests + network; degrades gracefully offline. Structured JSON audit line.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
FIG_DIR="${RECORD_STORE%/}/figures"
OUT_PNG="${FIG_DIR}/schematic.png"
OUT="${RECORD_STORE%/}/schematic.status.json"
mkdir -p "$FIG_DIR"
# Always (re)create the status sidecar so the contract's output_exists holds even with no key/network.
: > "$OUT"

ARGS=("$PROMPT" -o "$OUT_PNG")
if [ -n "${DOC_TYPE:-}" ]; then
  ARGS+=(--doc-type "$DOC_TYPE")
fi

LOG="${RECORD_STORE%/}/schematic.log"
: > "$LOG"
python3 "$HERE/generate_schematic.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true

if [ -s "$OUT_PNG" ]; then
  printf '{"tool":"generate_schematic","status":"ok","image":"%s","log":"%s"}\n' "$OUT_PNG" "$LOG" > "$OUT"
else
  printf '{"tool":"generate_schematic","status":"ok","image":null,"note":"no image produced (needs OPENROUTER_API_KEY + requests + network)","log":"%s"}\n' "$LOG" > "$OUT"
fi

# Guarantee a non-empty artifact no matter what.
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
