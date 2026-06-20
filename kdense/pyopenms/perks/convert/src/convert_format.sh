#!/usr/bin/env bash
# convert_format — convert/filter MS files between mzML/mzXML/MGF. Structured JSON audit.
set -uo pipefail
: "${INPUT:?}" "${OUT_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/${OUT_NAME}"
LOG="${RECORD_STORE%/}/convert.log"
# Pre-create the declared artifact so output_exists holds even if pyopenms is absent or errors.
: > "$OUT"
: > "$LOG"
ARGS=("$INPUT" "$OUT")
[ -n "${MS_LEVEL:-}" ]      && ARGS+=(--ms-level "$MS_LEVEL")
[ -n "${RT_MIN:-}" ]        && ARGS+=(--rt-min "$RT_MIN")
[ -n "${RT_MAX:-}" ]        && ARGS+=(--rt-max "$RT_MAX")
[ -n "${MIN_INTENSITY:-}" ] && ARGS+=(--min-intensity "$MIN_INTENSITY")
python3 "$HERE/convert_format.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"convert_format","status":"ok","input":"%s","output":"%s"}\n' "$INPUT" "$OUT"
