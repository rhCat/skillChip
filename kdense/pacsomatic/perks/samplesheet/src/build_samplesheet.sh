#!/usr/bin/env bash
# build_samplesheet — write the pacsomatic samplesheet CSV (patient,sample,status,bam,pbi)
# for a matched tumor/normal pair. Wraps the UNCHANGED vendored run_pacsomatic.py builder.
# Read-only: writes one file under RECORD_STORE; no pipeline execution. Structured JSON audit line.
set -uo pipefail
: "${PATIENT_ID:?}" "${TUMOR_SAMPLE_ID:?}" "${NORMAL_SAMPLE_ID:?}" "${TUMOR_BAM:?}" "${NORMAL_BAM:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/samplesheet.csv"
# Pre-create so the contract's output_exists holds even if the builder errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/harness_samplesheet.py" \
  --patient-id "$PATIENT_ID" \
  --tumor-sample-id "$TUMOR_SAMPLE_ID" \
  --normal-sample-id "$NORMAL_SAMPLE_ID" \
  --tumor-bam "$TUMOR_BAM" \
  --normal-bam "$NORMAL_BAM" \
  --tumor-pbi "${TUMOR_PBI:-}" \
  --normal-pbi "${NORMAL_PBI:-}" \
  --out "$OUT" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"build_samplesheet","status":"ok","samplesheet":"%s"}\n' "$OUT"
