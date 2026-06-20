#!/usr/bin/env bash
# filename_fast_path — localized from NVIDIA/skills nemo-retriever (Apache-2.0). Structured-JSON audit line.
# Filename fast path: when the query literally names a PDF basename in PDFS_DIR, extract its pages (pdfium),
# rank pages by query-token frequency, and emit a top-10 ranking + the top page's raw text. Read-only over PDFs.
set -uo pipefail
: "${QUERY:?}" "${RECORD_STORE:?}"
PDFS_DIR="${PDFS_DIR:-./pdfs}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${RECORD_STORE%/}/work"
OUT="${RECORD_STORE%/}/filename_fast_path.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python/retriever is absent or errors.
: > "$OUT"
# The core reads ./pdfs relative to cwd; stage a cwd whose ./pdfs resolves to PDFS_DIR (graceful if missing).
mkdir -p "$WORK"
rm -rf "$WORK/pdfs"
if [ -d "$PDFS_DIR" ]; then
  ln -s "$(cd "$PDFS_DIR" && pwd)" "$WORK/pdfs" 2>/dev/null || cp -R "$PDFS_DIR" "$WORK/pdfs" 2>/dev/null || mkdir -p "$WORK/pdfs"
else
  mkdir -p "$WORK/pdfs"
fi
( cd "$WORK" && python3 "$HERE/filename_fast_path.py" "${QUERY}" ) >>"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf 'NO_MATCH\n' > "$OUT"
printf '{"tool":"filename_fast_path","status":"ok","out":"%s"}\n' "$OUT"
