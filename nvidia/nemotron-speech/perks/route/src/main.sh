#!/usr/bin/env bash
# main — localized from NVIDIA/skills nemotron-speech (Apache-2.0). Structured-JSON audit line.
# Routes a Nemotron Speech (Riva) prompt to the right bundled reference via the vendored main.py.
# main.py prints its classification JSON to stdout (no --output flag), so we capture stdout into $OUT.
set -uo pipefail
: "${QUESTION:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/route.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"
python3 "$HERE/main.py" "${QUESTION}" --pretty > "$OUT" 2> "$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"main","status":"ok","out":"%s"}\n' "$OUT"
