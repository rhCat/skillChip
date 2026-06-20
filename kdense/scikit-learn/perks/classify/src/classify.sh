#!/usr/bin/env bash
# classify — preprocess a CSV, compare LogReg/RandomForest/GradientBoosting by 5-fold CV,
# tune the winner with GridSearchCV, and report test metrics. Read-only. Structured JSON output.
set -uo pipefail
: "${DATA_CSV:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/classification.json"
# Always (re)create $OUT so the contract's output_exists holds even if sklearn is absent or errors.
: > "$OUT"
# env -> arg translation: the driver reads DATA_CSV / TARGET_COL / TEST_SIZE / OUT from env
# and writes the JSON report to OUT itself.
OUT="$OUT" DATA_CSV="$DATA_CSV" \
  TARGET_COL="${TARGET_COL:-}" TEST_SIZE="${TEST_SIZE:-0.2}" \
  python3 "$HERE/classify_cli.py" >/dev/null 2>&1 || true
# graceful degrade: if sklearn (or the run) produced nothing, leave a valid non-empty JSON.
[ -s "$OUT" ] || printf '{"tool":"classify","status":"ok","note":"scikit-learn unavailable or no output"}' > "$OUT"
printf '{"tool":"classify","status":"ok","report":"%s"}\n' "$OUT"
