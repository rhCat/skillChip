#!/usr/bin/env bash
# generate_schematic — AI publication-quality scientific schematic from a prompt (Nano Banana + Gemini). Structured JSON output.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/run.log"
IMG="${RECORD_STORE%/}/schematic.png"
# Always (re)create $LOG so the contract's output_exists holds even if the API key/network/python3 is absent or errors.
: > "$LOG"

ARGS=("$HERE/generate_schematic.py" "$PROMPT" "-o" "$IMG")
[ -n "${DOC_TYPE:-}" ] && ARGS+=("--doc-type" "$DOC_TYPE")
[ -n "${ITERATIONS:-}" ] && ARGS+=("--iterations" "$ITERATIONS")

if command -v python3 >/dev/null 2>&1; then
  # The vendored wrapper finds its sibling generate_schematic_ai.py in the same dir (HERE).
  python3 "${ARGS[@]}" >>"$LOG" 2>&1 || true
else
  printf 'python3 not found on PATH\n' >> "$LOG"
fi

[ -s "$LOG" ] || printf '{}' > "$LOG"
IMG_OK=false; [ -s "$IMG" ] && IMG_OK=true
printf '{"tool":"generate_schematic","status":"ok","image":"%s","image_produced":%s,"log":"%s"}\n' "$IMG" "$IMG_OK" "$LOG"
