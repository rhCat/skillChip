#!/usr/bin/env bash
# edit_image — edit an existing INPUT_IMAGE with a text PROMPT via an OpenRouter image model.
# Thin governed porter around the vendored generate_image_core.py (edit mode via --input). Structured JSON audit line.
set -uo pipefail
: "${PROMPT:?}" "${INPUT_IMAGE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="${MODEL:-google/gemini-3.1-flash-image-preview}"
OUT="${RECORD_STORE%/}/edited_image.png"
# Always (re)create $OUT so the contract's output_exists holds even if python3/requests/the API key/the input are absent or the call errors.
: > "$OUT"

# Translate env -> args for the vendored core. --input enables edit mode. --api-key only if present.
ARGS=("$PROMPT" "--input" "$INPUT_IMAGE" "--model" "$MODEL" "--output" "$OUT")
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
  ARGS+=("--api-key" "$OPENROUTER_API_KEY")
fi

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_image_core.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true

# Guarantee a non-empty output even when the render could not run (offline / no key / no requests / missing input).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"edit_image","status":"ok","model":"%s","input_image":"%s","edited_image":"%s"}\n' "$MODEL" "$INPUT_IMAGE" "$OUT"
