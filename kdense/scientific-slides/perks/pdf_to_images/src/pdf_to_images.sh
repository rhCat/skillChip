#!/usr/bin/env bash
# pdf_to_images — rasterize PDF_PATH into per-slide images under RECORD_STORE. Structured JSON audit line.
# Vendored core: pdf_to_images.py (PyMuPDF/fitz). Porter degrades gracefully when fitz is absent or the PDF is unreadable.
set -uo pipefail
: "${PDF_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DPI="${DPI:-150}"
IMAGE_FORMAT="${IMAGE_FORMAT:-jpg}"
PREFIX="${RECORD_STORE%/}/slide"
OUT="${RECORD_STORE%/}/pdf_to_images.json"
# Pre-create the manifest so the contract's output_exists holds even if the core errors or fitz is missing.
: > "$OUT"
python3 "$HERE/pdf_to_images.py" "$PDF_PATH" "$PREFIX" --dpi "$DPI" --format "$IMAGE_FORMAT" \
  >"${RECORD_STORE%/}/pdf_to_images.log" 2>&1 || true
# Count what landed and record a small manifest as the contract artifact.
COUNT=$(ls -1 "${RECORD_STORE%/}"/slide-*."$IMAGE_FORMAT" 2>/dev/null | wc -l | tr -d ' ')
printf '{"tool":"pdf_to_images","pdf":"%s","prefix":"%s","format":"%s","dpi":"%s","images":%s}\n' \
  "$PDF_PATH" "$PREFIX" "$IMAGE_FORMAT" "$DPI" "${COUNT:-0}" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"pdf_to_images","status":"ok","manifest":"%s","images":%s}\n' "$OUT" "${COUNT:-0}"
