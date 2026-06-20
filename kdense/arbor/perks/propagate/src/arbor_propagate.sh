#!/usr/bin/env bash
# arbor_propagate — porter: abstract a leaf insight upward to ancestor nodes (Backpropagate, upward).
# With TO_ROOT=1 it also records the lesson as a global insight on the root. Thin env->arg wrapper
# around the vendored tree.py core (standalone stdlib CLI).
set -uo pipefail
: "${NODE:?}" "${INSIGHT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/propagate.txt"
mkdir -p "$RUN_DIR"
: > "$OUT"
# Bootstrap a run with a root + one child node (n1) if none exists, so NODE has ancestors.
if [ ! -f "$RUN_DIR/.arbor/tree.json" ]; then
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" init \
    --objective "${OBJECTIVE:-bootstrap run}" \
    --dev-eval "${DEV_EVAL:-true}" \
    --test-eval "${TEST_EVAL:-true}" --force >/dev/null 2>&1 || true
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" add-node \
    --parent n0 --hypothesis "bootstrap hypothesis" >/dev/null 2>&1 || true
fi
ARGS=()
[ "${TO_ROOT:-}" = "1" ] && ARGS+=(--to-root)
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" propagate \
  --node "$NODE" \
  --insight "$INSIGHT" ${ARGS[@]+"${ARGS[@]}"} >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_propagate","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
