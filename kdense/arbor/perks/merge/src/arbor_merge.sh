#!/usr/bin/env bash
# arbor_merge — porter: record a held-out merge-gate decision against the TEST evaluator; promote the
# candidate to M_best only if it improves the held-out score (Decide). Thin env->arg wrapper around
# the vendored tree.py core (standalone stdlib CLI). This records a decision in local state only —
# it does NOT run the evaluator or mutate any remote/live artifact.
set -uo pipefail
: "${NODE:?}" "${TEST_SCORE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/merge.txt"
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
[ -n "${BRANCH_REF:-}" ] && ARGS+=(--branch-ref "$BRANCH_REF")
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" merge \
  --node "$NODE" \
  --test-score "$TEST_SCORE" ${ARGS[@]+"${ARGS[@]}"} >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_merge","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
