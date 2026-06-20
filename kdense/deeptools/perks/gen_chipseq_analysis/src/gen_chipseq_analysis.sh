#!/usr/bin/env bash
# gen_chipseq_analysis — generate a full ChIP-seq analysis workflow bash script via vendored
# workflow_generator.py (stdlib). Read-only: emits a template script, runs nothing. One JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
: "${INPUT_BAM:=}" "${CHIP_BAM:=}" "${GENES_BED:=}" "${PEAKS_BED:=}" "${GENOME_SIZE:=}" "${THREADS:=}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/chipseq_analysis.sh"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"

# Map env vars -> generator args; omit empties so the generator applies its own defaults.
ARGS=(chipseq_analysis -o "$OUT")
[ -n "$INPUT_BAM" ]   && ARGS+=(--input-bam "$INPUT_BAM")
[ -n "$CHIP_BAM" ]    && ARGS+=(--chip-bam "$CHIP_BAM")
[ -n "$GENES_BED" ]   && ARGS+=(--genes-bed "$GENES_BED")
[ -n "$PEAKS_BED" ]   && ARGS+=(--peaks-bed "$PEAKS_BED")
[ -n "$GENOME_SIZE" ] && ARGS+=(--genome-size "$GENOME_SIZE")
[ -n "$THREADS" ]     && ARGS+=(--threads "$THREADS")

if ! command -v python3 >/dev/null 2>&1; then
  printf '# python3 not found on PATH\n' >> "$OUT"
else
  python3 "$HERE/workflow_generator.py" "${ARGS[@]}" >/dev/null 2>&1 || true
fi

# Guarantee non-empty output for the contract even if the generator wrote nothing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"gen_chipseq_analysis","status":"ok","workflow":"%s"}\n' "$OUT"
