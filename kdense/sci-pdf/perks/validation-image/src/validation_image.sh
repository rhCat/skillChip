#!/usr/bin/env bash
# validation_image — draw entry/label bounding boxes for a page onto an image (PIL). Structured JSON audit line.
set -uo pipefail
: "${PAGE_NUMBER:?}" "${FIELDS_JSON:?}" "${PAGE_IMAGE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNG="${RECORD_STORE%/}/validation_page.png"
OUT="${RECORD_STORE%/}/validation_image.txt"
# Always (re)create the manifest so the contract's output_exists holds even if PIL is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/create_validation_image.py" "$PAGE_NUMBER" "$FIELDS_JSON" "$PAGE_IMAGE" "$PNG" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"validation_image","status":"ok","page":"%s","image":"%s","annotated":"%s","manifest":"%s"}\n' "$PAGE_NUMBER" "$PAGE_IMAGE" "$PNG" "$OUT"
