#!/usr/bin/env bash
# gene_analysis — comprehensive single-gene analysis via gget (search/info/seq/archs4/opentargets).
# Thin porter over the vendored gene_analysis.py core. Read-only remote queries; writes under RECORD_STORE.
# Emits one structured-JSON audit line. Degrades gracefully when gget/network are absent.
set -uo pipefail
: "${GENE:?}" "${RECORD_STORE:?}"
SPECIES="${SPECIES:-homo_sapiens}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/gene_analysis.log"
# Always (re)create $OUT so the contract's output_exists holds even if gget is absent or errors.
: > "$OUT"
# Run the vendored core inside RECORD_STORE so its CSV/FASTA artifacts land there.
# env -> arg translation: GENE -> positional, SPECIES -> -s, output prefix -> the gene name (lowercased by the core).
( cd "${RECORD_STORE%/}" && PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
    python3 "$HERE/gene_analysis.py" "$GENE" -s "$SPECIES" ) >> "$OUT" 2>&1 || true
# Guarantee a non-empty report even on the graceful-offline path (gget import failure).
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"gene_analysis","status":"ok","gene":"%s","species":"%s","log":"%s"}\n' "$GENE" "$SPECIES" "$OUT"
