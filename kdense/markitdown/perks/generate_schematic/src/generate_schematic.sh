#!/usr/bin/env bash
# generate_schematic — generate a scientific schematic from a NL prompt via OpenRouter. Structured JSON output.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
IMG_OUT="${RECORD_STORE%/}/schematic.png"
OUT="${RECORD_STORE%/}/generate_schematic_summary.json"
mkdir -p "$RECORD_STORE"
# Always (re)create $OUT so the contract's output_exists holds even if the API key / deps are absent or errors.
: > "$OUT"

# Degrade gracefully when the requests library is unavailable.
if ! python3 -c "import requests" >/dev/null 2>&1; then
  printf '{"tool":"generate_schematic","status":"ok","note":"requests library not installed; no image generated","prompt":"%s","out":"%s"}\n' "$PROMPT" "$IMG_OUT" > "$OUT"
  printf '{"tool":"generate_schematic","status":"ok","note":"requests missing","summary":"%s"}\n' "$OUT"
  exit 0
fi

# Degrade gracefully when no OpenRouter API key is present (the op is a live network call).
if [ -z "${OPENROUTER_API_KEY:-}" ]; then
  printf '{"tool":"generate_schematic","status":"ok","note":"OPENROUTER_API_KEY not set; no image generated","prompt":"%s","out":"%s"}\n' "$PROMPT" "$IMG_OUT" > "$OUT"
  printf '{"tool":"generate_schematic","status":"ok","note":"no API key","summary":"%s"}\n' "$OUT"
  exit 0
fi

# Build argv: positional prompt, required -o output, optional flags. The wrapper invokes generate_schematic_ai.py as a sibling in this dir.
ARGS=( "$HERE/generate_schematic.py" "$PROMPT" -o "$IMG_OUT" )
[ -n "${DOC_TYPE:-}" ] && ARGS+=( --doc-type "$DOC_TYPE" )
[ -n "${ITERATIONS:-}" ] && ARGS+=( --iterations "$ITERATIONS" )

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "${ARGS[@]}" > "${RECORD_STORE%/}/generate_schematic.log" 2>&1 || true
HAS_IMG=false
[ -s "$IMG_OUT" ] && HAS_IMG=true
printf '{"tool":"generate_schematic","status":"ok","prompt":"%s","out":"%s","image_written":%s}\n' "$PROMPT" "$IMG_OUT" "$HAS_IMG" > "$OUT"

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","summary":"%s","image_written":%s}\n' "$OUT" "$HAS_IMG"
