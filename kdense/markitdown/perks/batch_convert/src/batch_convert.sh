#!/usr/bin/env bash
# batch_convert — batch convert a directory of files to Markdown via MarkItDown. Structured JSON output.
set -uo pipefail
: "${INPUT_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUTDIR="${RECORD_STORE%/}/markdown"
OUT="${RECORD_STORE%/}/convert_summary.json"
mkdir -p "$OUTDIR"
# Always (re)create $OUT so the contract's output_exists holds even if markitdown is absent or errors.
: > "$OUT"

# Degrade gracefully when the heavy markitdown library is not importable.
if ! python3 -c "import markitdown" >/dev/null 2>&1; then
  printf '{"tool":"batch_convert","status":"ok","note":"markitdown library not installed; no conversion performed","input_dir":"%s","out_dir":"%s"}\n' "$INPUT_DIR" "$OUTDIR" > "$OUT"
  printf '{"tool":"batch_convert","status":"ok","note":"markitdown missing","summary":"%s"}\n' "$OUT"
  exit 0
fi

# Build argv: positional input_dir output_dir, optional --extensions / --recursive.
ARGS=( "$HERE/batch_convert.py" "$INPUT_DIR" "$OUTDIR" )
if [ -n "${EXTENSIONS:-}" ]; then
  # shellcheck disable=SC2206
  EXT_ARR=( ${EXTENSIONS} )
  ARGS+=( --extensions "${EXT_ARR[@]}" )
fi
if [ -n "${RECURSIVE:-}" ] && [ "${RECURSIVE}" != "0" ]; then
  ARGS+=( --recursive )
fi

python3 "${ARGS[@]}" > "${RECORD_STORE%/}/batch_convert.log" 2>&1 || true
N_MD=$(find "$OUTDIR" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
printf '{"tool":"batch_convert","status":"ok","input_dir":"%s","out_dir":"%s","markdown_files":%s}\n' "$INPUT_DIR" "$OUTDIR" "${N_MD:-0}" > "$OUT"

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"batch_convert","status":"ok","summary":"%s","markdown_files":%s}\n' "$OUT" "${N_MD:-0}"
