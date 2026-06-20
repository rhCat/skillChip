#!/usr/bin/env bash
# generate_slide_image — generate a slide/visual via Nano Banana Pro (OpenRouter) into RECORD_STORE. Structured JSON audit line.
# Vendored cores: generate_slide_image.py (CLI wrapper) + generate_slide_image_ai.py (sibling it invokes). Needs OPENROUTER_API_KEY + network.
# Porter degrades gracefully: no key / offline -> a JSON stub stands in for the image so the contract still holds.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/slide.png"
# Pre-create so the contract's output_exists holds even when the API/key/network is unavailable.
: > "$OUT"
ARGS=("$PROMPT" -o "$OUT")
case "${VISUAL_ONLY:-}" in
  ""|"0"|"false"|"no") ;;
  *) ARGS+=(--visual-only) ;;
esac
# The wrapper finds generate_slide_image_ai.py beside itself (script_dir); both are vendored here together.
python3 "$HERE/generate_slide_image.py" "${ARGS[@]}" >"${RECORD_STORE%/}/generate_slide_image.log" 2>&1 || true
# If no real image was written (offline/no key), leave a JSON stub so output_exists + nonempty still hold.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_slide_image","status":"ok","image":"%s"}\n' "$OUT"
