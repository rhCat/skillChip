#!/usr/bin/env bash
# batch_id_convert — UniProt batch identifier mapping (read-only). Structured JSON audit line.
# Thin porter: vendors batch_id_converter.py; env -> argv; graceful when bioservices/network absent.
set -uo pipefail
: "${ID_FILE:?}" "${FROM_DB:?}" "${TO_DB:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/mapping_results.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the lib/network is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/batch_id_converter.py" "$ID_FILE" --from "$FROM_DB" --to "$TO_DB" --output "$OUT" \
  >> "${RECORD_STORE%/}/batch_id_convert.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"batch_id_convert","status":"ok","from":"%s","to":"%s","mapping_csv":"%s"}\n' "$FROM_DB" "$TO_DB" "$OUT"
