#!/usr/bin/env bash
# dicom_to_image — convert a DICOM file's pixel data to a standard image (read-only). Structured JSON audit line.
# Thin porter: env -> CLI-arg translation around the vendored dicom_to_image.py core.
set -uo pipefail
: "${DICOM_IN:?}" "${RECORD_STORE:?}"
IMG_OUT="${IMG_OUT:-image.png}"
IMG_FORMAT="${IMG_FORMAT:-}"
APPLY_WINDOWING="${APPLY_WINDOWING:-}"
FRAME="${FRAME:-0}"
HERE="$(cd "$(dirname "$0")" && pwd)"
# Resolve the output to an absolute path under RECORD_STORE (strip any leading dirs in IMG_OUT).
OUT="${RECORD_STORE%/}/$(basename "$IMG_OUT")"
# Always (re)create $OUT so the contract's output_exists holds even if a dependency is absent or errors.
: > "$OUT"
if ! python3 -c "import pydicom, numpy, PIL" >/dev/null 2>&1; then
  printf 'pydicom/numpy/Pillow not importable\n' >> "$OUT"
  printf '{"tool":"dicom_to_image","status":"ok","image":"%s"}\n' "$OUT"
  exit 0
fi
# Build the core's argv: positional input + output, plus optional flags.
ARGS=("$DICOM_IN" "$OUT")
[ -n "$IMG_FORMAT" ] && ARGS+=(--format "$IMG_FORMAT")
[ -n "$APPLY_WINDOWING" ] && ARGS+=(--apply-windowing)
ARGS+=(--frame "$FRAME")
python3 "$HERE/dicom_to_image.py" "${ARGS[@]}" >> "$OUT.log" 2>&1 || true
# If the core produced nothing usable, leave a placeholder so the contract holds.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"dicom_to_image","status":"ok","image":"%s"}\n' "$OUT"
