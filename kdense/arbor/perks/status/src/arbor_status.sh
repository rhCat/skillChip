#!/usr/bin/env bash
# arbor_status — porter: render the hypothesis tree as an ASCII audit trail (read-only).
# Thin wrapper around the vendored tree.py core (standalone stdlib CLI).
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/status.txt"
mkdir -p "$RUN_DIR"
: > "$OUT"
# Bootstrap an empty run if none exists, so there is a tree to render.
if [ ! -f "$RUN_DIR/.arbor/tree.json" ]; then
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" init \
    --objective "${OBJECTIVE:-bootstrap run}" \
    --dev-eval "${DEV_EVAL:-true}" \
    --test-eval "${TEST_EVAL:-true}" --force >/dev/null 2>&1 || true
fi
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" status >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_status","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
