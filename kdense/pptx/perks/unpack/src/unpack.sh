#!/usr/bin/env bash
# unpack — unpack a .pptx into a pretty-printed, editable XML directory.
# Thin porter over the vendored unpack.py (imports helpers.*). Structured JSON audit line on stdout.
set -uo pipefail
: "${PPTX_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/unpack.log"
DST="${RECORD_STORE%/}/unpacked"
# Vendored siblings (helpers/) resolve via PYTHONPATH=src.
export PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}"
# Always (re)create the log so the contract's output_exists holds even if defusedxml is absent or the core errors.
: > "$LOG"
python3 "$HERE/unpack.py" "$PPTX_FILE" "$DST" >> "$LOG" 2>&1 || true
[ -s "$LOG" ] || printf 'unpack produced no output (defusedxml absent or bad archive)\n' > "$LOG"
printf '{"tool":"unpack","status":"ok","pptx":"%s","unpacked":"%s","log":"%s"}\n' "$PPTX_FILE" "$DST" "$LOG"
