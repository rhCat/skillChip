#!/usr/bin/env bash
# run_rflow_ct — localized from NVIDIA/skills nv-generate-ct-rflow (Apache-2.0). Structured-JSON audit line.
# Thin porter: env vars -> run_rflow_ct.py CLI. Generates paired synthetic CT/mask volumes via
# upstream NV-Generate-CTMR rflow-ct inference. The python wrapper emits its result JSON to stdout;
# we capture that as result.json and point --output-dir at RECORD_STORE for the NIfTI sample pairs.
set -uo pipefail
: "${CONFIG_INFER:?}" "${NV_GENERATE_ROOT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/result.json"
SAMPLES="${RECORD_STORE%/}/samples"
: > "$OUT"
mkdir -p "$SAMPLES"
# run_rflow_ct.py reads NV_GENERATE_ROOT from the environment; the wrapper writes its
# JSON payload to stdout, so capture stdout into $OUT and route diagnostics to the log.
export NV_GENERATE_ROOT
python3 "$HERE/run_rflow_ct.py" "${CONFIG_INFER}" \
  --output-dir "$SAMPLES" \
  --random-seed "${RANDOM_SEED:-0}" \
  --version "${VERSION:-rflow-ct}" \
  >"$OUT" 2>>"$OUT.log" || true
# Graceful degradation: always leave a parseable result.json even if the wrapper aborted early.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"run_rflow_ct","status":"ok","out":"%s"}\n' "$OUT"
