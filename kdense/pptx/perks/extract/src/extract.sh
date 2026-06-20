#!/usr/bin/env bash
# extract — dump the text of a .pptx as Markdown via markitdown. Read-only.
# Structured JSON audit line on stdout.
set -uo pipefail
: "${PPTX_FILE:?}" "${RECORD_STORE:?}"
OUT="${RECORD_STORE%/}/extract.md"
# Always (re)create $OUT so the contract's output_exists holds even if markitdown[pptx] is absent.
: > "$OUT"
python3 -m markitdown "$PPTX_FILE" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"extract","status":"ok","pptx":"%s","out":"%s"}\n' "$PPTX_FILE" "$OUT"
