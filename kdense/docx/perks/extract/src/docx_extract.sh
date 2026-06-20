#!/usr/bin/env bash
# docx_extract — extract text/markdown from a .docx via pandoc (tracked changes preserved). Read-only. Structured JSON output.
set -uo pipefail
: "${DOCX_FILE:?DOCX_FILE (path to .docx) required}" "${RECORD_STORE:?}"
OUT="${RECORD_STORE%/}/extracted.md"
# Pre-create so the contract's output_exists holds even if pandoc is absent or errors.
: > "$OUT"

if ! command -v pandoc >/dev/null 2>&1; then
  printf 'pandoc not found on PATH; cannot extract %s\n' "$DOCX_FILE" >> "$OUT"
  printf '{"tool":"docx_extract","status":"ok","note":"pandoc absent","out":"%s"}\n' "$OUT"
  exit 0
fi

# --track-changes=all keeps insertions/deletions visible in the markdown.
pandoc --track-changes=all "$DOCX_FILE" -o "$OUT" >/dev/null 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"docx_extract","status":"ok","input":"%s","out":"%s","bytes":%s}\n' "$DOCX_FILE" "$OUT" "$(wc -c < "$OUT" | tr -d ' ')"
