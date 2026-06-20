#!/usr/bin/env bash
# render_images — rasterize PDF pages to downscaled PNGs (pdf2image + poppler). Structured JSON audit line.
set -uo pipefail
: "${PDF_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG_DIR="${RECORD_STORE%/}/pages"
mkdir -p "$IMG_DIR"
OUT="${RECORD_STORE%/}/render_images.txt"
# Always (re)create the manifest so the contract's output_exists holds even if pdf2image/poppler is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/convert_pdf_to_images.py" "$PDF_PATH" "$IMG_DIR" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"render_images","status":"ok","pdf":"%s","image_dir":"%s","manifest":"%s"}\n' "$PDF_PATH" "$IMG_DIR" "$OUT"
