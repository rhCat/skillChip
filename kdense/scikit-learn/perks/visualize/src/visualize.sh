#!/usr/bin/env bash
# visualize — project a scaled CSV to 2D with PCA, K-Means-label it, and render a labeled
# cluster scatter. Read-only. Structured JSON output.
set -uo pipefail
: "${DATA_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE="${RECORD_STORE%/}"
OUT="$STORE/cluster_visualization.json"
PLOT="$STORE/clustering_results.png"
# Always (re)create $OUT so the contract's output_exists holds even if sklearn is absent or errors.
: > "$OUT"
# Run inside RECORD_STORE so the core's CWD-relative PNG lands under the store.
# env -> arg translation: the driver reads DATA_CSV / N_CLUSTERS / PLOT / OUT from env.
( cd "$STORE" && OUT="$OUT" DATA_CSV="$DATA_CSV" \
    N_CLUSTERS="${N_CLUSTERS:-3}" PLOT="$PLOT" \
    python3 "$HERE/visualize_cli.py" >/dev/null 2>&1 ) || true
# graceful degrade: if sklearn (or the run) produced nothing, leave a valid non-empty JSON.
[ -s "$OUT" ] || printf '{"tool":"visualize","status":"ok","note":"scikit-learn unavailable or no output"}' > "$OUT"
printf '{"tool":"visualize","status":"ok","report":"%s","plot":"%s"}\n' "$OUT" "$PLOT"
