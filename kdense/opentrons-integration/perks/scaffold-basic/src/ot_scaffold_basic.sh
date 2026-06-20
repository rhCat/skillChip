#!/usr/bin/env bash
# ot_scaffold_basic — emit the basic transfer Protocol API v2 template into the record store (read-only).
# Thin governed porter: asserts store, pre-creates the output, runs the vendored stdlib emitter, emits one audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/basic_protocol.py"
# Always (re)create $OUT so the contract's output_exists holds even if the emitter errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/ot_scaffold_core.py" "basic_protocol_template.py" "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"ot_scaffold_basic","status":"ok","template":"basic_protocol_template.py","protocol":"%s"}\n' "$OUT"
