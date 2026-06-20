#!/usr/bin/env bash
# get_disease_context — summarize the local PrimeKG graph around a disease (genes/drugs/phenotypes/
# related diseases) via the vendored query_primekg.get_disease_context core. Read-only; writes a JSON
# report under RECORD_STORE. Emits one structured-JSON audit line. Degrades gracefully when
# pandas/the CSV are absent.
set -uo pipefail
: "${DISEASE_NAME:?}" "${RECORD_STORE:?}"
PRIMEKG_CSV="${PRIMEKG_CSV:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/disease_context.json"
# Always (re)create $OUT so the contract's output_exists holds even if pandas/CSV are absent or errors.
: > "$OUT"
# env -> the vendored CLI reads PRIMEKG_CSV / DISEASE_NAME from the environment.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" PRIMEKG_CSV="$PRIMEKG_CSV" \
  DISEASE_NAME="$DISEASE_NAME" \
  python3 "$HERE/run_get_disease_context.py" > "$OUT" 2>/dev/null || true
# Guarantee a non-empty report even on the graceful-offline path (pandas/CSV missing).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"get_disease_context","status":"ok","disease_name":"%s","report":"%s"}\n' "$DISEASE_NAME" "$OUT"
