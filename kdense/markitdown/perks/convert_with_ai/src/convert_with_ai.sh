#!/usr/bin/env bash
# convert_with_ai — convert one file to Markdown with AI image descriptions via OpenRouter. Structured JSON output.
set -uo pipefail
: "${INPUT_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
MD_OUT="${RECORD_STORE%/}/converted.md"
OUT="${RECORD_STORE%/}/convert_with_ai_summary.json"
mkdir -p "$RECORD_STORE"
# Always (re)create $OUT so the contract's output_exists holds even if deps/API are absent or errors.
: > "$OUT"

# Degrade gracefully when the heavy libraries are not importable.
if ! python3 -c "import markitdown, openai" >/dev/null 2>&1; then
  printf '{"tool":"convert_with_ai","status":"ok","note":"markitdown/openai library not installed; no conversion performed","input_file":"%s","out":"%s"}\n' "$INPUT_FILE" "$MD_OUT" > "$OUT"
  printf '{"tool":"convert_with_ai","status":"ok","note":"deps missing","summary":"%s"}\n' "$OUT"
  exit 0
fi

# Build argv: positional input output, optional flags. (API key flows via OPENROUTER_API_KEY env.)
ARGS=( "$HERE/convert_with_ai.py" "$INPUT_FILE" "$MD_OUT" )
[ -n "${MODEL:-}" ] && ARGS+=( --model "$MODEL" )
[ -n "${PROMPT_TYPE:-}" ] && ARGS+=( --prompt-type "$PROMPT_TYPE" )
[ -n "${CUSTOM_PROMPT:-}" ] && ARGS+=( --custom-prompt "$CUSTOM_PROMPT" )

python3 "${ARGS[@]}" > "${RECORD_STORE%/}/convert_with_ai.log" 2>&1 || true
HAS_MD=false
[ -s "$MD_OUT" ] && HAS_MD=true
printf '{"tool":"convert_with_ai","status":"ok","input_file":"%s","out":"%s","markdown_written":%s}\n' "$INPUT_FILE" "$MD_OUT" "$HAS_MD" > "$OUT"

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"convert_with_ai","status":"ok","summary":"%s","markdown_written":%s}\n' "$OUT" "$HAS_MD"
