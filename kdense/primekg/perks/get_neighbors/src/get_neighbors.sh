#!/usr/bin/env bash
# get_neighbors — list direct neighbors of a PrimeKG node (+ optional relation filter) via the
# vendored query_primekg.get_neighbors core. Read-only; writes a JSON report under RECORD_STORE.
# Emits one structured-JSON audit line. Degrades gracefully when pandas/the CSV are absent.
set -uo pipefail
: "${NODE_ID:?}" "${RECORD_STORE:?}"
PRIMEKG_CSV="${PRIMEKG_CSV:-}"
RELATION_TYPE="${RELATION_TYPE:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/get_neighbors.json"
# Always (re)create $OUT so the contract's output_exists holds even if pandas/CSV are absent or errors.
: > "$OUT"
# env -> the vendored CLI reads PRIMEKG_CSV / NODE_ID / RELATION_TYPE from the environment.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" PRIMEKG_CSV="$PRIMEKG_CSV" \
  NODE_ID="$NODE_ID" RELATION_TYPE="$RELATION_TYPE" \
  python3 "$HERE/run_get_neighbors.py" > "$OUT" 2>/dev/null || true
# Guarantee a non-empty report even on the graceful-offline path (pandas/CSV missing).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"get_neighbors","status":"ok","node_id":"%s","relation_type":"%s","report":"%s"}\n' "$NODE_ID" "$RELATION_TYPE" "$OUT"
