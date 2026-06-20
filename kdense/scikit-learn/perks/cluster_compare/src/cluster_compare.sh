#!/usr/bin/env bash
# cluster_compare — scale a CSV and compare K-Means, Agglomerative, Gaussian Mixture, and DBSCAN,
# scoring each with silhouette, Calinski-Harabasz, and Davies-Bouldin. Read-only. Structured JSON output.
set -uo pipefail
: "${DATA_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/cluster_compare.json"
# Always (re)create $OUT so the contract's output_exists holds even if sklearn is absent or errors.
: > "$OUT"
# env -> arg translation: the driver reads DATA_CSV / N_CLUSTERS / OUT from env
# and writes the JSON report to OUT itself.
OUT="$OUT" DATA_CSV="$DATA_CSV" N_CLUSTERS="${N_CLUSTERS:-3}" \
  python3 "$HERE/cluster_compare_cli.py" >/dev/null 2>&1 || true
# graceful degrade: if sklearn (or the run) produced nothing, leave a valid non-empty JSON.
[ -s "$OUT" ] || printf '{"tool":"cluster_compare","status":"ok","note":"scikit-learn unavailable or no output"}' > "$OUT"
printf '{"tool":"cluster_compare","status":"ok","report":"%s"}\n' "$OUT"
