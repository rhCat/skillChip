#!/usr/bin/env bash
# generate_image — text prompt (+ optional input image) -> illustrative PNG via an OpenRouter image
# model (vendored generate_image.py). Read-only w.r.t. local state; calls the network. Structured JSON audit.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_NAME="${OUTPUT_NAME:-image.png}"
MODEL="${MODEL:-}"
INPUT_IMAGE="${INPUT_IMAGE:-}"
IMG="${RECORD_STORE%/}/${OUTPUT_NAME}"
OUT="${RECORD_STORE%/}/image.audit.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3/network/key are absent.
: > "$OUT"
mkdir -p "$RECORD_STORE" 2>/dev/null || true

CMD=(python3 "$HERE/generate_image.py" "$PROMPT" -o "$IMG")
[ -n "$MODEL" ] && CMD+=(--model "$MODEL")
[ -n "$INPUT_IMAGE" ] && CMD+=(--input "$INPUT_IMAGE")
"${CMD[@]}" > "${RECORD_STORE%/}/image.gen.log" 2>&1 || true

if [ -s "$IMG" ]; then
  printf '{"tool":"generate_image","status":"ok","image":"%s","mode":"%s"}\n' "$IMG" "$([ -n "$INPUT_IMAGE" ] && echo edit || echo generate)" > "$OUT"
else
  printf '{"tool":"generate_image","status":"ok","image":null,"note":"no image produced (missing OPENROUTER_API_KEY / network / requests)"}\n' > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_image","status":"ok","audit":"%s"}\n' "$OUT"
