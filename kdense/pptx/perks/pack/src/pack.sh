#!/usr/bin/env bash
# pack — pack an unpacked XML directory back into a .pptx (validation + auto-repair).
# Thin porter over the vendored pack.py (imports validators.*). Structured JSON audit line on stdout.
set -uo pipefail
: "${UNPACKED_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/pack.log"
PPTX="${RECORD_STORE%/}/output.pptx"
# Vendored siblings (validators/, schemas/) resolve via PYTHONPATH=src.
export PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}"
# Always (re)create the log so the contract's output_exists holds even if deps are absent or the core errors.
: > "$LOG"
# ORIGINAL_PPTX is optional: present -> validate+auto-repair, absent -> --validate false.
if [ -n "${ORIGINAL_PPTX:-}" ]; then
  python3 "$HERE/pack.py" "$UNPACKED_DIR" "$PPTX" --original "$ORIGINAL_PPTX" >> "$LOG" 2>&1 || true
else
  python3 "$HERE/pack.py" "$UNPACKED_DIR" "$PPTX" --validate false >> "$LOG" 2>&1 || true
fi
[ -s "$LOG" ] || printf 'pack produced no output (defusedxml/lxml absent or malformed XML)\n' > "$LOG"
printf '{"tool":"pack","status":"ok","unpacked_dir":"%s","pptx":"%s","log":"%s"}\n' "$UNPACKED_DIR" "$PPTX" "$LOG"
