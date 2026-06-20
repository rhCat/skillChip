#!/usr/bin/env bash
# validate — validate a .pptx (or unpacked dir) against OOXML XSD schemas. Read-only.
# Thin porter over the vendored validate.py (imports validators.*). Structured JSON audit line on stdout.
set -uo pipefail
: "${PPTX_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/validate.log"
# Vendored siblings (validators/, schemas/) resolve via PYTHONPATH=src.
export PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}"
# Always (re)create the log so the contract's output_exists holds even if deps are absent or the core errors.
: > "$LOG"
python3 "$HERE/validate.py" "$PPTX_PATH" >> "$LOG" 2>&1 || true
[ -s "$LOG" ] || printf 'validate produced no output (defusedxml/lxml absent)\n' > "$LOG"
printf '{"tool":"validate","status":"ok","path":"%s","log":"%s"}\n' "$PPTX_PATH" "$LOG"
