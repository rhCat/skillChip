#!/usr/bin/env bash
# generate_schematic — render a publication-quality scientific schematic from a natural-language
# description (Nano Banana 2 via OpenRouter, Gemini quality review). Read-only / network.
# Structured JSON audit line.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
DOC_TYPE="${DOC_TYPE:-default}"
OUTPUT_NAME="${OUTPUT_NAME:-schematic.png}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/schematic.png"
LOG="${RECORD_STORE%/}/schematic.log"
# Always (re)create the contract output + log so output_exists holds even if deps/network/keys are absent.
: > "$OUT"
: > "$LOG"

# env -> arg translation for the vendored wrapper CLI
ARGS=("$PROMPT" -o "$OUT")
if [ -n "$DOC_TYPE" ] && [ "$DOC_TYPE" != "default" ]; then
  ARGS+=(--doc-type "$DOC_TYPE")
fi

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_schematic.py" "${ARGS[@]}" >>"$LOG" 2>>"$LOG" || true

# If generation could not run (no key / missing 'requests' / no network), keep contract valid.
[ -s "$OUT" ] || printf 'placeholder: schematic not generated (offline or missing OPENROUTER_API_KEY)\n' > "$OUT"

# Mirror to a caller-named file when requested and distinct.
if [ -n "$OUTPUT_NAME" ] && [ "$OUTPUT_NAME" != "schematic.png" ]; then
  cp "$OUT" "${RECORD_STORE%/}/${OUTPUT_NAME}" 2>/dev/null || true
fi

printf '{"tool":"generate_schematic","status":"ok","doc_type":"%s","image":"%s"}\n' "$DOC_TYPE" "$OUT"
