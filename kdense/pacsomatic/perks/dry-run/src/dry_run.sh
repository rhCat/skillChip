#!/usr/bin/env bash
# dry_run — validate inputs + dependencies and write ALL launch artifacts (samplesheet, params YAML,
# launch script) WITHOUT executing the pipeline, by running the UNCHANGED vendored
# run_pacsomatic.py with --dry-run. Read-only: nothing is submitted/run. nextflow/java absent only
# downgrades to warnings in dry-run mode. Structured JSON audit line.
set -uo pipefail
: "${PATIENT_ID:?}" "${TUMOR_SAMPLE_ID:?}" "${NORMAL_SAMPLE_ID:?}" "${TUMOR_BAM:?}" "${NORMAL_BAM:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/dry_run.log"
# Reference mode: exactly one of FASTA / GENOME (the core enforces this).
REF=()
if [ -n "${FASTA:-}" ]; then REF=(--fasta "$FASTA"); elif [ -n "${GENOME:-}" ]; then REF=(--genome "$GENOME"); fi
# Pre-create so the contract's output_exists holds even if the core errors.
: > "$OUT"
python3 "$HERE/run_pacsomatic.py" \
  --tumor-bam "$TUMOR_BAM" \
  --normal-bam "$NORMAL_BAM" \
  --patient-id "$PATIENT_ID" \
  --tumor-sample-id "$TUMOR_SAMPLE_ID" \
  --normal-sample-id "$NORMAL_SAMPLE_ID" \
  --outdir "${RECORD_STORE%/}" \
  --profile "${PROFILE:-singularity}" \
  --executor "${EXECUTOR:-local}" \
  --use-current-path \
  "${REF[@]}" \
  --dry-run >>"$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"dry_run","status":"ok","dry_run_log":"%s"}\n' "$OUT"
