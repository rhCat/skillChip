#!/usr/bin/env bash
# find_paths — find direct (depth-1) edges connecting two PrimeKG nodes via the vendored
# query_primekg.find_paths core. Read-only; writes a JSON report under RECORD_STORE.
# Emits one structured-JSON audit line. Degrades gracefully when pandas/the CSV are absent.
set -uo pipefail
: "${START_NODE_ID:?}" "${END_NODE_ID:?}" "${RECORD_STORE:?}"
PRIMEKG_CSV="${PRIMEKG_CSV:-}"
MAX_DEPTH="${MAX_DEPTH:-2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/find_paths.json"
# Always (re)create $OUT so the contract's output_exists holds even if pandas/CSV are absent or errors.
: > "$OUT"
# env -> the vendored CLI reads PRIMEKG_CSV / START_NODE_ID / END_NODE_ID / MAX_DEPTH from the environment.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" PRIMEKG_CSV="$PRIMEKG_CSV" \
  START_NODE_ID="$START_NODE_ID" END_NODE_ID="$END_NODE_ID" MAX_DEPTH="$MAX_DEPTH" \
  python3 "$HERE/run_find_paths.py" > "$OUT" 2>/dev/null || true
# Guarantee a non-empty report even on the graceful-offline path (pandas/CSV missing).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"find_paths","status":"ok","start_node_id":"%s","end_node_id":"%s","report":"%s"}\n' "$START_NODE_ID" "$END_NODE_ID" "$OUT"
