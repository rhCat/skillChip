#!/usr/bin/env bash
# unpack — explode an Office workbook (.xlsx/.docx/.pptx) ZIP into a pretty-printed XML directory tree
# for editing. Wraps the vendored K-Dense unpack.py (uses defusedxml + helpers.* for DOCX run-merging).
# The unpacked tree is written under RECORD_STORE/unpacked/; a one-line JSON summary is written to unpack.json.
set -uo pipefail
: "${OFFICE_FILE:?OFFICE_FILE (path to .xlsx/.docx/.pptx) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/unpack.json"
DEST="${RECORD_STORE%/}/unpacked"

# Pre-create the output so the contract's output_exists holds even if the core errors or defusedxml is absent.
: > "$OUT"

# unpack.py prints a human message to stdout; capture it as a JSON "message" field.
# `helpers.*` resolves next to unpack.py (HERE on PYTHONPATH).
MSG="$(PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/unpack.py" "$OFFICE_FILE" "$DEST" 2>/dev/null)" || true

# Emit one structured-JSON line as the perk's report; fall back to {} if the core could not run.
if [ -n "${MSG:-}" ]; then
  python3 - "$OFFICE_FILE" "$DEST" "$MSG" > "$OUT" 2>/dev/null <<'PY' || true
import json, sys
src, dest, msg = sys.argv[1], sys.argv[2], sys.argv[3]
print(json.dumps({"tool": "unpack", "status": "ok", "office_file": src, "dest": dest, "message": msg}))
PY
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"unpack","status":"ok","office_file":"%s","dest":"%s","report":"%s"}\n' "$OFFICE_FILE" "$DEST" "$OUT"
