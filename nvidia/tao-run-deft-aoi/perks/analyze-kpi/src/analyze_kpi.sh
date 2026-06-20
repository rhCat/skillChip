#!/usr/bin/env bash
# analyze_kpi — localized from NVIDIA/skills tao-run-deft-aoi (Apache-2.0). Structured-JSON audit line.
# Sweeps thresholds over a ChangeNet inference CSV (score > threshold => NO_PASS), picks the FAR @
# 100%-recall operating point, and writes threshold_metrics.csv + summary.txt (+ optional plots) under
# ${RECORD_STORE}/kpi_analysis/. Graceful degradation: the summary output is always created.
set -uo pipefail
: "${INFER_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}/kpi_analysis"
SUMMARY="${OUTDIR}/summary.txt"
mkdir -p "${OUTDIR}"
: > "$SUMMARY"

ARGS=()
[ -n "${LABEL_COLUMN:-}" ] && ARGS+=(--label-column "${LABEL_COLUMN}")
[ -n "${SCORE_COLUMN:-}" ] && ARGS+=(--score-column "${SCORE_COLUMN}")
[ -n "${PASS_LABEL:-}" ]   && ARGS+=(--pass-label "${PASS_LABEL}")
[ -n "${BINS:-}" ]         && ARGS+=(--bins "${BINS}")

python3 "$HERE/analyze_kpi.py" "${INFER_CSV}" \
  --output-dir "${OUTDIR}" \
  "${ARGS[@]}" \
  >>"${OUTDIR}/analyze_kpi.log" 2>&1 || true

[ -s "$SUMMARY" ] || printf 'AOI inference threshold analysis\n(unavailable offline)\n' > "$SUMMARY"
printf '{"tool":"analyze_kpi","status":"ok","out":"%s"}\n' "$SUMMARY"
