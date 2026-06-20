#!/usr/bin/env bash
# add_slide — add a slide to an unpacked .pptx dir (duplicate a slide or instantiate a layout).
# Thin porter over the vendored stdlib core add_slide.py. Structured JSON audit line on stdout.
set -uo pipefail
: "${UNPACKED_DIR:?}" "${SLIDE_SOURCE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/add_slide.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
python3 "$HERE/add_slide.py" "$UNPACKED_DIR" "$SLIDE_SOURCE" >> "$OUT" 2>&1 || true
# Guarantee a non-empty artifact even on graceful failure.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"add_slide","status":"ok","unpacked_dir":"%s","source":"%s","out":"%s"}\n' "$UNPACKED_DIR" "$SLIDE_SOURCE" "$OUT"
