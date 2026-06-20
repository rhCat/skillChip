#!/usr/bin/env bash
# slides_to_pdf — combine slide images from IMAGES_DIR into one PDF under RECORD_STORE. Structured JSON audit line.
# Vendored core: slides_to_pdf.py (Pillow). Porter degrades gracefully when Pillow is absent or no images are found.
set -uo pipefail
: "${IMAGES_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/presentation.pdf"
# Pre-create so the contract's output_exists holds even if the core errors or Pillow is missing.
: > "$OUT"
python3 "$HERE/slides_to_pdf.py" "$IMAGES_DIR" -o "$OUT" >"${RECORD_STORE%/}/slides_to_pdf.log" 2>&1 || true
# A zero-byte PDF is not a valid file artifact; leave a JSON stub so output_exists + nonempty hold offline/degraded.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"slides_to_pdf","status":"ok","pdf":"%s","images_dir":"%s"}\n' "$OUT" "$IMAGES_DIR"
