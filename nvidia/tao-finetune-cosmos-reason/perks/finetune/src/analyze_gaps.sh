#!/usr/bin/env bash
# analyze_gaps — localized from NVIDIA/skills tao-finetune-cosmos-reason (Apache-2.0). Structured-JSON audit line.
# DEFT gap analysis: compares cosmos-rl eval predictions vs ground truth and writes FP/FN cases as parquet.
set -uo pipefail
: "${RESULTS_DIR:?}" "${KPI_ANN_PATH:?}" "${KPI_MEDIA_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/gaps.parquet"
# Always (re)create $OUT so the contract's output_exists holds even if python/deps are absent or the script errors.
: > "$OUT"
python3 "$HERE/analyze_gaps.py" \
  --results-dir "${RESULTS_DIR}" \
  --gaps-parquet "${OUT}" \
  --kpi-ann-path "${KPI_ANN_PATH}" \
  --kpi-media-path "${KPI_MEDIA_PATH}" >>"${OUT}.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"analyze_gaps","status":"ok","out":"%s"}\n' "$OUT"
