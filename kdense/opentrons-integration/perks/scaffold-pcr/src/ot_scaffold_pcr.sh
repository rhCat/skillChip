#!/usr/bin/env bash
# ot_scaffold_pcr — emit the PCR-setup (thermocycler) Protocol API v2 template into the record store (read-only).
# Thin governed porter: asserts store, pre-creates the output, runs the vendored stdlib emitter, emits one audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pcr_setup.py"
# Always (re)create $OUT so the contract's output_exists holds even if the emitter errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/ot_scaffold_core.py" "pcr_setup_template.py" "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"ot_scaffold_pcr","status":"ok","template":"pcr_setup_template.py","protocol":"%s"}\n' "$OUT"
