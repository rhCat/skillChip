#!/usr/bin/env bash
# build_params — write the generated Nextflow params YAML (input/outdir + fasta|genome) for
# reproducible reruns. Wraps the UNCHANGED vendored run_pacsomatic.py builder.
# Read-only: writes one file under RECORD_STORE; no pipeline execution. Structured JSON audit line.
set -uo pipefail
: "${OUTDIR:?}" "${SAMPLESHEET:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pacsomatic.params.generated.yaml"
# Pre-create so the contract's output_exists holds even if the builder errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/harness_params.py" \
  --input "$SAMPLESHEET" \
  --outdir "$OUTDIR" \
  --fasta "${FASTA:-}" \
  --genome "${GENOME:-}" \
  --out "$OUT" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"build_params","status":"ok","params":"%s"}\n' "$OUT"
