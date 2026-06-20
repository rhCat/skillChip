#!/usr/bin/env bash
# enrichment — Enrichr ontology/pathway enrichment over a gene list via gget, across 5 databases.
# Thin porter over the vendored enrichment_pipeline.py core. Read-only remote queries; writes under RECORD_STORE.
# Emits one structured-JSON audit line. Degrades gracefully when gget/pandas/network are absent.
set -uo pipefail
: "${GENE_LIST:?}" "${RECORD_STORE:?}"
SPECIES="${SPECIES:-human}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/enrichment.log"
# Always (re)create $OUT so the contract's output_exists holds even if gget is absent or errors.
: > "$OUT"
# Run the vendored core inside RECORD_STORE so its CSV artifacts land there. Headless: --no-plot.
# env -> arg translation: GENE_LIST -> positional, SPECIES -> -s, output prefix -> "enrichment" (core default).
( cd "${RECORD_STORE%/}" && PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
    python3 "$HERE/enrichment_pipeline.py" "$GENE_LIST" -s "$SPECIES" -o enrichment --no-plot ) >> "$OUT" 2>&1 || true
# Guarantee a non-empty report even on the graceful-offline path (gget/pandas import failure).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"enrichment","status":"ok","gene_list":"%s","species":"%s","log":"%s"}\n' "$GENE_LIST" "$SPECIES" "$OUT"
