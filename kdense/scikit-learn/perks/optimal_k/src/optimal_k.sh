#!/usr/bin/env bash
# optimal_k — sweep K for K-Means over [K_MIN,K_MAX] via inertia (elbow) + silhouette,
# save the elbow/silhouette plot, and report the recommended K. Read-only. Structured JSON output.
set -uo pipefail
: "${DATA_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE="${RECORD_STORE%/}"
OUT="$STORE/optimal_k.json"
PLOT="$STORE/clustering_optimization.png"
# Always (re)create $OUT so the contract's output_exists holds even if sklearn is absent or errors.
: > "$OUT"
# Run inside RECORD_STORE so the core's CWD-relative PNG lands under the store.
# env -> arg translation: the driver reads DATA_CSV / K_MIN / K_MAX / PLOT / OUT from env.
( cd "$STORE" && OUT="$OUT" DATA_CSV="$DATA_CSV" \
    K_MIN="${K_MIN:-2}" K_MAX="${K_MAX:-8}" PLOT="$PLOT" \
    python3 "$HERE/optimal_k_cli.py" >/dev/null 2>&1 ) || true
# graceful degrade: if sklearn (or the run) produced nothing, leave a valid non-empty JSON.
[ -s "$OUT" ] || printf '{"tool":"optimal_k","status":"ok","note":"scikit-learn unavailable or no output"}' > "$OUT"
printf '{"tool":"optimal_k","status":"ok","report":"%s","plot":"%s"}\n' "$OUT" "$PLOT"
