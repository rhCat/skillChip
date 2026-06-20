#!/usr/bin/env bash
# benchmark_charts — localized from NVIDIA/skills deepstream-import-vision-model (Apache-2.0).
# Entry porter for the `benchmark-charts` perk: renders the 5 fixed benchmark PNG charts from a
# benchmark_data.json (Report phase, Step 8) — independently usable to (re)build the chart set.
# Translates env vars -> the vendored impl's CLI args, writes charts + a manifest under
# RECORD_STORE, and ALWAYS emits ONE line of structured JSON on stdout (graceful degradation:
# matplotlib may be absent or the JSON may be missing/malformed).
set -uo pipefail
: "${BENCHMARK_DATA:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/benchmark-charts.json"
CHART_DIR="${CHART_DIR:-${RECORD_STORE%/}/charts}"

# Pre-create the chart output dir + manifest so output_exists holds even when matplotlib is
# absent or the JSON is malformed (the vendored impl writes the PNGs only on success).
mkdir -p "$CHART_DIR" 2>/dev/null || true

# The vendored impl reads positional args: <output_dir> <json_data_file>.
LOG="${RECORD_STORE%/}/benchmark-charts.log"
python3 "$HERE/generate-benchmark-charts.py" "${CHART_DIR}" "${BENCHMARK_DATA}" >"$LOG" 2>&1 || true

N_CHARTS=$(find "$CHART_DIR" -maxdepth 1 -name 'chart_*.png' 2>/dev/null | grep -c . | head -1); N_CHARTS="${N_CHARTS:-0}"

# Emit the step manifest as the perk's named output.
if command -v python3 >/dev/null 2>&1; then
  BENCHMARK_DATA="$BENCHMARK_DATA" CHART_DIR="$CHART_DIR" N_CHARTS="$N_CHARTS" \
  python3 - <<'PYEOF' > "$OUT" 2>/dev/null || printf '{}' > "$OUT"
import json, os
print(json.dumps({
    "skill": "deepstream-import-vision-model",
    "perk": "benchmark-charts",
    "step": "report",
    "benchmark_data": os.environ.get("BENCHMARK_DATA", ""),
    "chart_dir": os.environ.get("CHART_DIR", ""),
    "charts_written": int(os.environ.get("N_CHARTS", "0") or 0),
}))
PYEOF
else
  printf '{"skill":"deepstream-import-vision-model","perk":"benchmark-charts","step":"report","benchmark_data":"%s","chart_dir":"%s","charts_written":%s}' \
    "$BENCHMARK_DATA" "$CHART_DIR" "$N_CHARTS" > "$OUT"
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"benchmark_charts","status":"ok","out":"%s","chart_dir":"%s","charts_written":%s}\n' "$OUT" "$CHART_DIR" "$N_CHARTS"
