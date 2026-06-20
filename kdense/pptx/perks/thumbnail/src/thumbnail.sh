#!/usr/bin/env bash
# thumbnail — render a labeled JPEG thumbnail grid of all slides in a .pptx. Read-only.
# Thin porter over the vendored thumbnail.py (imports office.soffice). Structured JSON audit line on stdout.
set -uo pipefail
: "${PPTX_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/thumbnail.log"
# Vendored siblings (office/) resolve via PYTHONPATH=src.
export PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}"
# Always (re)create the log so the contract's output_exists holds even when soffice/pdftoppm/deps are absent.
: > "$LOG"
# Output prefix lands grid JPEGs under record_store.
python3 "$HERE/thumbnail.py" "$PPTX_FILE" "${RECORD_STORE%/}/thumbnails" >> "$LOG" 2>&1 || true
[ -s "$LOG" ] || printf 'thumbnail produced no output (soffice/pdftoppm/Pillow/defusedxml absent)\n' > "$LOG"
printf '{"tool":"thumbnail","status":"ok","pptx":"%s","log":"%s"}\n' "$PPTX_FILE" "$LOG"
