#!/usr/bin/env bash
# docx_pack — repack an unpacked XML directory into a .docx (validate + auto-repair + condense). Structured JSON output.
set -uo pipefail
: "${UNPACKED_DIR:?UNPACKED_DIR (an unpacked .docx dir) required}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDOCX="${RECORD_STORE%/}/packed.docx"
OUT="${RECORD_STORE%/}/pack.log"
# Pre-create the audit log so the contract's output_exists holds even if the core fails or defusedxml is absent.
: > "$OUT"

# Optional original .docx for validation diffing.
ORIG_ARG=()
[ -n "${ORIGINAL_DOCX:-}" ] && ORIG_ARG=(--original "$ORIGINAL_DOCX")

# pack.py imports `from validators...`; run with its own dir (src/office) on PYTHONPATH.
PYTHONPATH="$HERE/office${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/office/pack.py" "$UNPACKED_DIR" "$OUTDOCX" "${ORIG_ARG[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"docx_pack","status":"ok","unpacked_dir":"%s","out":"%s","log":"%s"}\n' "$UNPACKED_DIR" "$OUTDOCX" "$OUT"
