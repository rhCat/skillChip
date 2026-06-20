#!/usr/bin/env bash
# arbor_prune — porter: prune a falsified node and its subtree, recording the reason as a negative
# constraint (Decide). Thin env->arg wrapper around the vendored tree.py core (standalone stdlib CLI).
set -uo pipefail
: "${NODE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/prune.txt"
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
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" prune \
  --node "$NODE" \
  --reason "${REASON:-}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_prune","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
