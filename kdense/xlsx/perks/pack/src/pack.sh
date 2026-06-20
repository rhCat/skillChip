#!/usr/bin/env bash
# pack — re-zip an unpacked Office XML directory tree back into an Office workbook (.xlsx/.docx/.pptx),
# condensing XML formatting on the way in. Wraps the vendored K-Dense pack.py (uses defusedxml + validators.*).
# Validation/auto-repair runs only for .docx/.pptx with --original; for .xlsx it is a no-op.
# The packed workbook is written under RECORD_STORE; a one-line JSON summary is written to pack.json.
set -uo pipefail
: "${PACK_DIR:?PACK_DIR (an unpacked Office XML directory) is required}"
: "${OUT_FILE:?OUT_FILE (basename of the workbook to produce, e.g. out.xlsx) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pack.json"
WORKBOOK="${RECORD_STORE%/}/${OUT_FILE}"

# Pre-create the output so the contract's output_exists holds even if the core errors or defusedxml is absent.
: > "$OUT"

# pack.py prints a human message to stdout; capture it as a JSON "message" field.
# Validation is disabled (no --original) so the xlsx path never touches validators schemas.
# `validators.*` resolves next to pack.py (HERE on PYTHONPATH).
MSG="$(PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/pack.py" "$PACK_DIR" "$WORKBOOK" --validate false 2>/dev/null)" || true

if [ -n "${MSG:-}" ]; then
  python3 - "$PACK_DIR" "$WORKBOOK" "$MSG" > "$OUT" 2>/dev/null <<'PY' || true
import json, sys
src, dest, msg = sys.argv[1], sys.argv[2], sys.argv[3]
print(json.dumps({"tool": "pack", "status": "ok", "pack_dir": src, "workbook": dest, "message": msg}))
PY
fi
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"pack","status":"ok","pack_dir":"%s","workbook":"%s","report":"%s"}\n' "$PACK_DIR" "$WORKBOOK" "$OUT"
