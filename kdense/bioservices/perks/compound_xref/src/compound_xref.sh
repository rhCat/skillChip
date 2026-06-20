#!/usr/bin/env bash
# compound_xref — KEGG/ChEBI/ChEMBL compound cross-reference (read-only). Structured JSON audit line.
# Thin porter: vendors compound_cross_reference.py; env -> argv; graceful when bioservices/network absent.
set -uo pipefail
: "${COMPOUND:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/compound_xref.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the lib/network is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/compound_cross_reference.py" "$COMPOUND" --output "$OUT" \
  >> "${RECORD_STORE%/}/compound_xref.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"compound_xref","status":"ok","compound":"%s","xref_report":"%s"}\n' "$COMPOUND" "$OUT"
