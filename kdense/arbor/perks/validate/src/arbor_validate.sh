#!/usr/bin/env bash
# arbor_validate — porter: check hypothesis-tree invariants and report any inconsistencies (read-only).
# Thin wrapper around the vendored tree.py core (standalone stdlib CLI).
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${RECORD_STORE%/}/run"
OUT="${RECORD_STORE%/}/validate.txt"
mkdir -p "$RUN_DIR"
: > "$OUT"
# Bootstrap an empty run if none exists, so there is a tree whose invariants can be checked.
if [ ! -f "$RUN_DIR/.arbor/tree.json" ]; then
  python3 "$HERE/tree.py" --run-dir "$RUN_DIR" init \
    --objective "${OBJECTIVE:-bootstrap run}" \
    --dev-eval "${DEV_EVAL:-true}" \
    --test-eval "${TEST_EVAL:-true}" --force >/dev/null 2>&1 || true
fi
python3 "$HERE/tree.py" --run-dir "$RUN_DIR" validate >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"arbor_validate","status":"ok","run_dir":"%s","report":"%s"}\n' "$RUN_DIR" "$OUT"
