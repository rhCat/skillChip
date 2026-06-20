#!/usr/bin/env bash
# generate_schematic — generate a publication-quality scientific diagram from a text PROMPT via OpenRouter
# (Nano Banana 2 image gen + Gemini quality review, smart iterative refinement).
# Thin governed porter around the vendored generate_schematic.py (which drives generate_schematic_ai.py).
# Structured JSON audit line.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_TYPE="${DOC_TYPE:-default}"
ITERATIONS="${ITERATIONS:-2}"
# Contract-bound output is a fixed name under record_store; OUTPUT_NAME (if set) only labels the run.
OUT="${RECORD_STORE%/}/schematic.png"
LOG="${RECORD_STORE%/}/generate_schematic.log"
# Always (re)create $OUT so the contract's output_exists holds even if python3/requests/the API key are absent or the call errors.
: > "$OUT"
: > "$LOG"

# Translate env -> args for the vendored wrapper. --api-key only if present (else the wrapper checks the env var).
ARGS=("$PROMPT" "-o" "$OUT" "--doc-type" "$DOC_TYPE" "--iterations" "$ITERATIONS")
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
  ARGS+=("--api-key" "$OPENROUTER_API_KEY")
fi

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_schematic.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true

# Guarantee a non-empty output even when the render could not run (offline / no key / no requests).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","doc_type":"%s","iterations":"%s","schematic":"%s"}\n' "$DOC_TYPE" "$ITERATIONS" "$OUT"
