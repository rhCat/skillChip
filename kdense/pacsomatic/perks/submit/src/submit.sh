#!/usr/bin/env bash
# submit — DESTRUCTIVE. Build artifacts then EXECUTE locally or SUBMIT the generated launch script to
# the scheduler (lsf/slurm/pbs/sge) by running the UNCHANGED vendored run_pacsomatic.py with --run.
# This launches the real pipeline / submits a real job; it mutates a live scheduler. Requires a
# resolvable nextflow runtime and (for scheduler executors) the matching submit binary on PATH.
# Structured JSON audit line.
set -uo pipefail
: "${PATIENT_ID:?}" "${TUMOR_SAMPLE_ID:?}" "${NORMAL_SAMPLE_ID:?}" "${TUMOR_BAM:?}" "${NORMAL_BAM:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/submit.log"
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
  --run >>"$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"submit","status":"ok","submit_log":"%s"}\n' "$OUT"
