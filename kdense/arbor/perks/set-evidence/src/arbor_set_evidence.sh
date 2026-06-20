#!/usr/bin/env bash
# arbor_set_evidence — porter: write an executor's report (dev_score / result / insight / branch_ref)
# into its node (Backpropagate, leaf). Thin env->arg wrapper around the vendored tree.py core.
set -uo pipefail
: "${NODE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/set_evidence.txt"
mkdir -p "$RUN_DIR"
: > "$OUT"
# Bootstrap a run with a root + one child node (n1) if none exists, so NODE resolves.
if [ ! -f "$RUN_DIR/.arbor/tree.json" ]; then
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" init \
    --objective "${OBJECTIVE:-bootstrap run}" \
    --dev-eval "${DEV_EVAL:-true}" \
    --test-eval "${TEST_EVAL:-true}" --force >/dev/null 2>&1 || true
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" add-node \
    --parent n0 --hypothesis "bootstrap hypothesis" >/dev/null 2>&1 || true
fi
ARGS=()
[ -n "${DEV_SCORE:-}" ]  && ARGS+=(--dev-score "$DEV_SCORE")
[ -n "${RESULT:-}" ]     && ARGS+=(--result "$RESULT")
[ -n "${INSIGHT:-}" ]    && ARGS+=(--insight "$INSIGHT")
[ -n "${BRANCH_REF:-}" ] && ARGS+=(--branch-ref "$BRANCH_REF")
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" set-evidence \
  --node "$NODE" ${ARGS[@]+"${ARGS[@]}"} >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_set_evidence","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
