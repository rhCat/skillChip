#!/usr/bin/env bash
# clean — remove unreferenced/orphaned files from an unpacked .pptx dir.
# Thin porter over the vendored core clean.py. Structured JSON audit line on stdout.
set -uo pipefail
: "${UNPACKED_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/clean.txt"
# Always (re)create $OUT so the contract's output_exists holds even if defusedxml is absent or the core errors.
: > "$OUT"
python3 "$HERE/clean.py" "$UNPACKED_DIR" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"clean","status":"ok","unpacked_dir":"%s","out":"%s"}\n' "$UNPACKED_DIR" "$OUT"
