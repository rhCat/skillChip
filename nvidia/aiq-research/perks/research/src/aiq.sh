#!/usr/bin/env bash
# aiq — localized from NVIDIA/skills aiq-research (Apache-2.0). Structured-JSON audit line.
# Submits an async deep-research job to a reachable AI-Q backend, polls, and writes the report JSON.
set -uo pipefail
: "${AIQ_QUERY:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/report.json"
# Always (re)create $OUT so the contract's output_exists holds even if python3/backend are absent or error.
: > "$OUT"

# AIQ_SERVER_URL is read from the environment by aiq.py (defaults to http://localhost:8000).
# AIQ_AGENT_TYPE is the optional second positional arg to the `research` command.
if command -v python3 >/dev/null 2>&1; then
  if [ -n "${AIQ_AGENT_TYPE:-}" ]; then
    python3 "$HERE/aiq.py" research "$AIQ_QUERY" "$AIQ_AGENT_TYPE" >"$OUT" 2>>"$OUT.log" || true
  else
    python3 "$HERE/aiq.py" research "$AIQ_QUERY" >"$OUT" 2>>"$OUT.log" || true
  fi
else
  printf 'python3 not found on PATH\n' >> "$OUT.log"
fi

# Graceful degradation: guarantee a valid (if empty) JSON artifact for the contract.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"aiq","status":"ok","report":"%s"}\n' "$OUT"
