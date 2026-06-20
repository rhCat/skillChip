#!/usr/bin/env bash
# convert_literature — convert a dir of scientific PDFs to Markdown + metadata + INDEX/catalog. Structured JSON output.
set -uo pipefail
: "${INPUT_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUTDIR="${RECORD_STORE%/}/literature"
OUT="${RECORD_STORE%/}/convert_literature_summary.json"
mkdir -p "$OUTDIR"
# Always (re)create $OUT so the contract's output_exists holds even if markitdown is absent or errors.
: > "$OUT"

# Degrade gracefully when the heavy markitdown library is not importable.
if ! python3 -c "import markitdown" >/dev/null 2>&1; then
  printf '{"tool":"convert_literature","status":"ok","note":"markitdown library not installed; no conversion performed","input_dir":"%s","out_dir":"%s"}\n' "$INPUT_DIR" "$OUTDIR" > "$OUT"
  printf '{"tool":"convert_literature","status":"ok","note":"markitdown missing","summary":"%s"}\n' "$OUT"
  exit 0
fi

# Build argv: positional input_dir output_dir, optional flags.
ARGS=( "$HERE/convert_literature.py" "$INPUT_DIR" "$OUTDIR" )
if [ -n "${ORGANIZE_BY_YEAR:-}" ] && [ "${ORGANIZE_BY_YEAR}" != "0" ]; then
  ARGS+=( --organize-by-year )
fi
if [ -n "${CREATE_INDEX:-}" ] && [ "${CREATE_INDEX}" != "0" ]; then
  ARGS+=( --create-index )
fi
if [ -n "${RECURSIVE:-}" ] && [ "${RECURSIVE}" != "0" ]; then
  ARGS+=( --recursive )
fi

python3 "${ARGS[@]}" > "${RECORD_STORE%/}/convert_literature.log" 2>&1 || true
N_MD=$(find "$OUTDIR" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
HAS_CATALOG=false
[ -f "$OUTDIR/catalog.json" ] && HAS_CATALOG=true
printf '{"tool":"convert_literature","status":"ok","input_dir":"%s","out_dir":"%s","markdown_files":%s,"catalog":%s}\n' "$INPUT_DIR" "$OUTDIR" "${N_MD:-0}" "$HAS_CATALOG" > "$OUT"

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"convert_literature","status":"ok","summary":"%s","markdown_files":%s}\n' "$OUT" "${N_MD:-0}"
