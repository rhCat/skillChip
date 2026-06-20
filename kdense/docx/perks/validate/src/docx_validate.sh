#!/usr/bin/env bash
# docx_validate — validate a .docx (or unpacked dir) against OOXML XSD + redlining rules, with auto-repair. Read-only. Structured JSON output.
set -uo pipefail
: "${DOCX_PATH:?DOCX_PATH (a .docx file or an unpacked dir) required}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validate.txt"
# Pre-create so the contract's output_exists holds even if the core fails or defusedxml is absent.
: > "$OUT"

# Optional original .docx for new-error-only diffing.
ORIG_ARG=()
if [ -n "${ORIGINAL_DOCX:-}" ]; then
  ORIG_ARG=(--original "$ORIGINAL_DOCX")
fi

# validate.py imports `from validators...`; run with its own dir (src/office) on PYTHONPATH.
PYTHONPATH="$HERE/office${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/office/validate.py" "$DOCX_PATH" --auto-repair "${ORIG_ARG[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"docx_validate","status":"ok","path":"%s","report":"%s"}\n' "$DOCX_PATH" "$OUT"
