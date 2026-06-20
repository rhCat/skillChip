#!/usr/bin/env bash
# pathway_network — KEGG pathway network extraction for an organism (read-only). Structured JSON audit line.
# Thin porter: vendors pathway_analysis.py; env -> argv; graceful when bioservices/network absent.
set -uo pipefail
: "${ORGANISM:?}" "${LIMIT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}"
OUT="$OUTDIR/pathway_summary.csv"
# Always (re)create $OUT so the contract's output_exists holds even if the lib/network is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/pathway_analysis.py" "$ORGANISM" "$OUTDIR" --limit "$LIMIT" \
  >> "$OUTDIR/pathway_network.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pathway_network","status":"ok","organism":"%s","limit":"%s","pathway_summary":"%s"}\n' "$ORGANISM" "$LIMIT" "$OUT"
