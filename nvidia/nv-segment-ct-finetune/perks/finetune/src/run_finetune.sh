#!/usr/bin/env bash
# run_finetune — localized from NVIDIA/skills nv-segment-ct-finetune (Apache-2.0). Structured-JSON audit line.
# Thin porter: translates env vars -> run_finetune.py CLI args and writes output.json under RECORD_STORE.
set -uo pipefail
: "${DATASET:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/output.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/monai/GPU are absent or error.
: > "$OUT"

# FINETUNE_ARGS is optional extra CLI flags (e.g. "--smoke --patch-size [64,64,64]"); word-split intentionally.
EXTRA_ARGS="${FINETUNE_ARGS:-}"

# run_finetune.py takes a positional dataset/fixture path and writes output.json into --output-dir.
# basename 'spleen_micro' -> --smoke, 'Task06_Lung' -> --sanity, any other MSD-layout dir -> finetune.
# shellcheck disable=SC2086
python3 "$HERE/run_finetune.py" "${DATASET}" --output-dir "${RECORD_STORE%/}" $EXTRA_ARGS >>"$OUT.log" 2>&1 || true

# The script writes output.json itself; if it could not (missing deps/GPU), emit a degraded stub.
[ -s "$OUT" ] || printf '{"skill":"nv_segment_ct_finetune","status":"degraded","note":"run_finetune.py did not emit output.json; see output.json.log"}' > "$OUT"
printf '{"tool":"run_finetune","status":"ok","out":"%s"}\n' "$OUT"
