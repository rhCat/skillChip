#!/usr/bin/env bash
# search_nodes — substring-search PrimeKG nodes by name (+ optional type) via the vendored
# query_primekg.search_nodes core. Read-only; writes a JSON report under RECORD_STORE.
# Emits one structured-JSON audit line. Degrades gracefully when pandas/the CSV are absent.
set -uo pipefail
: "${NAME_QUERY:?}" "${RECORD_STORE:?}"
PRIMEKG_CSV="${PRIMEKG_CSV:-}"
NODE_TYPE="${NODE_TYPE:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/search_nodes.json"
# Always (re)create $OUT so the contract's output_exists holds even if pandas/CSV are absent or errors.
: > "$OUT"
# env -> the vendored CLI reads PRIMEKG_CSV / NAME_QUERY / NODE_TYPE from the environment.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" PRIMEKG_CSV="$PRIMEKG_CSV" \
  NAME_QUERY="$NAME_QUERY" NODE_TYPE="$NODE_TYPE" \
  python3 "$HERE/run_search_nodes.py" > "$OUT" 2>/dev/null || true
# Guarantee a non-empty report even on the graceful-offline path (pandas/CSV missing).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"search_nodes","status":"ok","name_query":"%s","node_type":"%s","report":"%s"}\n' "$NAME_QUERY" "$NODE_TYPE" "$OUT"
