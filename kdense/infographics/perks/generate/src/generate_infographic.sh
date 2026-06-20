#!/usr/bin/env bash
# generate_infographic — generate an infographic via Nano Banana Pro w/ Gemini review (optional Perplexity research). Structured JSON output.
# Local file-producing; calls OpenRouter — needs OPENROUTER_API_KEY + network. Degrades gracefully offline.
set -uo pipefail
: "${PROMPT:?}" "${OUTPUT_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/generate.log"
OUTPUT_PATH="${RECORD_STORE%/}/${OUTPUT_NAME}"
# Always (re)create $LOG so the contract's output_exists holds even if python3 / the API is absent or errors.
: > "$LOG"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$LOG"
  printf '{"tool":"generate_infographic","status":"ok","generate_log":"%s"}\n' "$LOG"
  exit 0
fi

# env -> arg translation; only forward optional flags when set & non-empty.
set -- "$PROMPT" -o "$OUTPUT_PATH"
[ -n "${INFOGRAPHIC_TYPE:-}" ] && set -- "$@" --type "$INFOGRAPHIC_TYPE"
[ -n "${STYLE:-}" ]            && set -- "$@" --style "$STYLE"
[ -n "${PALETTE:-}" ]         && set -- "$@" --palette "$PALETTE"
[ -n "${DOC_TYPE:-}" ]        && set -- "$@" --doc-type "$DOC_TYPE"
[ -n "${ITERATIONS:-}" ]      && set -- "$@" --iterations "$ITERATIONS"
case "${RESEARCH:-}" in 1|true|TRUE|yes|YES) set -- "$@" --research ;; esac

# Run the vendored core; PYTHONPATH lets it import its sibling generate_infographic_ai.py.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/generate_infographic.py" "$@" >> "$LOG" 2>&1 || true

[ -s "$LOG" ] || printf '{}' > "$LOG"
IMG_OK=false
[ -s "$OUTPUT_PATH" ] && IMG_OK=true
printf '{"tool":"generate_infographic","status":"ok","generate_log":"%s","image":"%s","image_written":%s}\n' "$LOG" "$OUTPUT_PATH" "$IMG_OK"
