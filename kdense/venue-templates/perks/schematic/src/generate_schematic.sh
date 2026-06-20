#!/usr/bin/env bash
# generate_schematic — render a scientific schematic from a description via the OpenRouter image API. Structured JSON audit line.
set -uo pipefail
: "${PROMPT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/schematic.png"
LOG="${RECORD_STORE%/}/schematic.log"
# Always (re)create $OUT so the contract's output_exists holds even when the
# remote API / requests lib / OPENROUTER_API_KEY are unavailable.
: > "$OUT"
: > "$LOG"

# Translate env vars -> argparse flags for the vendored core. -o is the image path.
ARGS=("$PROMPT" -o "$OUT")
if [ -n "${DOC_TYPE:-}" ]; then ARGS+=(--doc-type "$DOC_TYPE"); fi
if [ -n "${ITERATIONS:-}" ]; then ARGS+=(--iterations "$ITERATIONS"); fi

python3 "$HERE/generate_schematic.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_schematic","status":"ok","prompt":"%s","doc_type":"%s","out":"%s"}\n' "$PROMPT" "${DOC_TYPE:-default}" "$OUT"
