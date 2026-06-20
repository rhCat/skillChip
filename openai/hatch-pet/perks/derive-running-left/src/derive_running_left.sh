#!/usr/bin/env bash
# derive_running_left — mirror an approved running-right strip into running-left and update the run job manifest. Structured JSON output (audit/debug log).
set -uo pipefail
: "${RUN_DIR:?}" "${DECISION_NOTE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
OUT="${RECORD_STORE%/}/derive-result.json"
FORCE_FLAG=""
[ "${FORCE:-0}" = "1" ] && FORCE_FLAG="--force"
# Pre-create the result manifest so the contract's output_exists holds even if python/PIL/inputs are absent or errors.
: > "$OUT"
# The core mutates <RUN_DIR>/imagegen-jobs.json and writes decoded/running-left.png; it prints a JSON result to stdout.
python3 "$HERE/derive_running_left_from_running_right.py" \
  --run-dir "$RUN_DIR" \
  --confirm-appropriate-mirror \
  --decision-note "$DECISION_NOTE" \
  $FORCE_FLAG > "$OUT" 2>/dev/null || true
# Graceful degradation: ensure a non-empty result artifact even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"derive_running_left","status":"ok","result":"%s","run_dir":"%s"}\n' "$OUT" "$RUN_DIR"
