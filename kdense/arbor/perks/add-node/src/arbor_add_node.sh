#!/usr/bin/env bash
# arbor_add_node — porter: add a pending child hypothesis under a parent (Ideate).
# Thin env->arg wrapper around the vendored tree.py core (standalone stdlib CLI).
set -uo pipefail
: "${PARENT:?}" "${HYPOTHESIS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/add_node.txt"
mkdir -p "$RUN_DIR"
: > "$OUT"
# Bootstrap an empty run with a root (n0) if none exists, so PARENT=n0 resolves.
if [ ! -f "$RUN_DIR/.arbor/tree.json" ]; then
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" init \
    --objective "${OBJECTIVE:-bootstrap run}" \
    --dev-eval "${DEV_EVAL:-true}" \
    --test-eval "${TEST_EVAL:-true}" --force >/dev/null 2>&1 || true
fi
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" add-node \
  --parent "$PARENT" \
  --hypothesis "$HYPOTHESIS" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_add_node","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
