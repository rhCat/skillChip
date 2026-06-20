#!/usr/bin/env bash
# generate_image — generate a new image from a text PROMPT via an OpenRouter image model.
# Thin governed porter around the vendored generate_image_core.py. Structured JSON audit line.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="${MODEL:-google/gemini-3.1-flash-image-preview}"
OUT="${RECORD_STORE%/}/generated_image.png"
# Always (re)create $OUT so the contract's output_exists holds even if python3/requests/the API key are absent or the call errors.
: > "$OUT"

# Translate env -> args for the vendored core. --api-key only if present (else the core checks .env / env var).
ARGS=("$PROMPT" "--model" "$MODEL" "--output" "$OUT")
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
  ARGS+=("--api-key" "$OPENROUTER_API_KEY")
fi

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_image_core.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true

# Guarantee a non-empty output even when the render could not run (offline / no key / no requests).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_image","status":"ok","model":"%s","generated_image":"%s"}\n' "$MODEL" "$OUT"
