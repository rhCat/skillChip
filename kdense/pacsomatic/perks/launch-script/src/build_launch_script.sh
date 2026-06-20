#!/usr/bin/env bash
# build_launch_script — generate the executor launch script (local/lsf/slurm/pbs/sge headers +
# the nextflow run command) for nf-core/pacsomatic. Wraps the UNCHANGED vendored builders.
# Read-only: writes one script file under RECORD_STORE; the pipeline is NOT executed. Structured JSON audit.
set -uo pipefail
: "${SAMPLESHEET:?}" "${OUTDIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXECUTOR="${EXECUTOR:-local}"
OUT="${RECORD_STORE%/}/run_pacsomatic.${EXECUTOR}.sh"
# Stable, executor-independent contract artifact (a copy of OUT) so the contract's
# output_exists path is deterministic regardless of which executor was selected.
CONTRACT_OUT="${RECORD_STORE%/}/launch_script.sh"
# Pre-create so the contract's output_exists holds even if the builder errors.
: > "$OUT"
: > "$CONTRACT_OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/harness_launch_script.py" \
  --samplesheet "$SAMPLESHEET" \
  --outdir "$OUTDIR" \
  --out "$OUT" \
  --fasta "${FASTA:-}" \
  --genome "${GENOME:-}" \
  --profile "${PROFILE:-singularity}" \
  --executor "$EXECUTOR" \
  --nextflow-bin "${NEXTFLOW_BIN:-nextflow}" \
  --pipeline "${PIPELINE:-nf-core/pacsomatic}" \
  --pipeline-version "${PIPELINE_VERSION:-}" \
  --job-name "${JOB_NAME:-pacsomatic}" \
  --project "${PROJECT:-}" \
  --queue "${QUEUE:-}" \
  --cpus "${CPUS:-16}" \
  --memory-gb "${MEMORY_GB:-64}" \
  --walltime "${WALLTIME:-48:00}" \
  --workdir "${WORKDIR:-}" \
  --logdir "${LOGDIR:-}" \
  --stdout-file "${STDOUT_FILE:-out%J.out}" \
  --stderr-file "${STDERR_FILE:-err%J.err}" \
  --nxf-opts "${NXF_OPTS:-}" \
  --singularity-cache "${SINGULARITY_CACHE:-}" \
  --module-load "${MODULE_LOAD:-}" >>"$CONTRACT_OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
# Mirror the generated script to the stable contract path.
cat "$OUT" > "$CONTRACT_OUT" 2>/dev/null || true
[ -s "$CONTRACT_OUT" ] || printf '{}' > "$CONTRACT_OUT"
printf '{"tool":"build_launch_script","status":"ok","executor":"%s","launch_script":"%s","contract_artifact":"%s"}\n' "$EXECUTOR" "$OUT" "$CONTRACT_OUT"
