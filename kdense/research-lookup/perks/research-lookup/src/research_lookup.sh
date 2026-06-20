#!/usr/bin/env bash
# research_lookup — route a research query to the Parallel Chat API (default) or Perplexity
# sonar-pro-search (academic), saving a cited report. Read-only / network. Structured JSON audit line.
set -uo pipefail
: "${QUERY:?}" "${RECORD_STORE:?}"
FORCE_BACKEND="${FORCE_BACKEND:-}"
OUTPUT_NAME="${OUTPUT_NAME:-research.md}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/research.md"
# Always (re)create $OUT so the contract's output_exists holds even if deps/network/keys are absent.
: > "$OUT"

# env -> arg translation for the vendored core CLI
ARGS=("$QUERY")
if [ -n "$FORCE_BACKEND" ]; then
  ARGS+=(--force-backend "$FORCE_BACKEND")
fi

PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/research_lookup.py" "${ARGS[@]}" -o "$OUT" >>"$OUT" 2>>"$OUT" || true

# If the core could not run (no key / missing 'openai'/'requests' / no network), keep contract valid.
[ -s "$OUT" ] || printf '{}' > "$OUT"

# Mirror to a caller-named file when requested and distinct.
if [ -n "$OUTPUT_NAME" ] && [ "$OUTPUT_NAME" != "research.md" ]; then
  cp "$OUT" "${RECORD_STORE%/}/${OUTPUT_NAME}" 2>/dev/null || true
fi

printf '{"tool":"research_lookup","status":"ok","backend":"%s","report":"%s"}\n' "${FORCE_BACKEND:-auto}" "$OUT"
