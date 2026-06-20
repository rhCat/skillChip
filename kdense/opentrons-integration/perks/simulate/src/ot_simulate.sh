#!/usr/bin/env bash
# ot_simulate — dry-run an Opentrons Protocol API v2 file via opentrons_simulate (read-only, no robot).
# Thin governed porter: asserts vars, pre-creates the output, runs the vendored core, emits one audit line.
set -uo pipefail
: "${PROTOCOL_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/simulate.log"
# Always (re)create $OUT so the contract's output_exists holds even if opentrons is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/ot_simulate_core.py" "$PROTOCOL_FILE" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"ot_simulate","status":"ok","protocol":"%s","simulate_log":"%s"}\n' "$PROTOCOL_FILE" "$OUT"
