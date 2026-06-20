#!/usr/bin/env bash
# arbor_observe — porter: render the Observe projection of the current research state (read-only).
# Thin wrapper around the vendored tree.py core. The logic lives in tree.py (standalone stdlib CLI).
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/observe.txt"
mkdir -p "$RUN_DIR"
: > "$OUT"
# Bootstrap an empty run if none exists yet, so the projection has a tree to read.
if [ ! -f "$RUN_DIR/.arbor/tree.json" ]; then
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" init \
    --objective "${OBJECTIVE:-bootstrap run}" \
    --dev-eval "${DEV_EVAL:-true}" \
    --test-eval "${TEST_EVAL:-true}" --force >/dev/null 2>&1 || true
fi
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" observe >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_observe","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
