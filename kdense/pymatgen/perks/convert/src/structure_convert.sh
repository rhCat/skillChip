#!/usr/bin/env bash
# structure_convert — convert one crystal-structure file to OUTPUT_FORMAT via vendored pymatgen
# structure_converter.py. Read-only. One structured-JSON audit line on stdout.
set -uo pipefail
: "${INPUT_FILE:?}" "${OUTPUT_FORMAT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${RECORD_STORE%/}/convert.log"
# Always (re)create $OUT so the contract's output_exists holds even if pymatgen is absent or errors.
: > "$OUT"

# Resolve INPUT_FILE to an absolute path (core script globs/opens relative to cwd).
case "$INPUT_FILE" in
  /*) IN_ABS="$INPUT_FILE" ;;
  *)  IN_ABS="$(pwd)/$INPUT_FILE" ;;
esac

CONVERTED="${RECORD_STORE%/}/structure.${OUTPUT_FORMAT}"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 not found on PATH\n' >> "$OUT"
else
  # Run the core in RECORD_STORE so its relative output lands there; pass explicit output path.
  ( cd "${RECORD_STORE%/}" && python3 "$HERE/structure_converter.py" "$IN_ABS" "$CONVERTED" ) >> "$OUT" 2>&1 || true
fi

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"structure_convert","status":"ok","input":"%s","format":"%s","converted":"%s","log":"%s"}\n' "$IN_ABS" "$OUTPUT_FORMAT" "$CONVERTED" "$OUT"
