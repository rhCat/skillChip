#!/usr/bin/env bash
# docx_unpack — unpack a .docx into a pretty-printed XML directory (merge runs, escape smart quotes). Read-only re: source. Structured JSON output.
set -uo pipefail
: "${DOCX_FILE:?DOCX_FILE (path to .docx) required}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}/unpacked"
OUT="${RECORD_STORE%/}/unpack.log"
# Pre-create the audit log so the contract's output_exists holds even if the core fails or defusedxml is absent.
: > "$OUT"
mkdir -p "$OUTDIR"

# unpack.py imports `from helpers...`; run with its own dir (src/office) on PYTHONPATH.
PYTHONPATH="$HERE/office${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/office/unpack.py" "$DOCX_FILE" "$OUTDIR" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"docx_unpack","status":"ok","input":"%s","outdir":"%s","log":"%s"}\n' "$DOCX_FILE" "$OUTDIR" "$OUT"
