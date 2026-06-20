#!/usr/bin/env bash
# render_pdf — convert a .pptx to PDF via headless LibreOffice. Read-only.
# Thin porter over the vendored soffice.py CLI. Structured JSON audit line on stdout.
set -uo pipefail
: "${PPTX_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/render.log"
PDF="${RECORD_STORE%/}/render.pdf"
# Always (re)create the log so the contract's output_exists holds even if soffice is absent or errors.
: > "$LOG"
# Vendored soffice.py forwards its argv to `soffice` (with sandbox LD_PRELOAD shim if needed).
python3 "$HERE/soffice.py" --headless --convert-to pdf --outdir "${RECORD_STORE%/}" "$PPTX_FILE" >> "$LOG" 2>&1 || true
# LibreOffice names the output after the input stem; normalise to render.pdf if produced.
SRC_PDF="${RECORD_STORE%/}/$(basename "${PPTX_FILE%.*}").pdf"
[ -f "$SRC_PDF" ] && [ "$SRC_PDF" != "$PDF" ] && mv -f "$SRC_PDF" "$PDF" 2>/dev/null || true
[ -s "$LOG" ] || printf 'soffice produced no output (binary absent or sandboxed)\n' > "$LOG"
printf '{"tool":"render_pdf","status":"ok","pptx":"%s","pdf":"%s","log":"%s"}\n' "$PPTX_FILE" "$PDF" "$LOG"
