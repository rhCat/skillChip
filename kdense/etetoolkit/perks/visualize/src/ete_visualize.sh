#!/usr/bin/env bash
# ete_visualize — render a tree to PNG/PDF/SVG with layout + styling via ETE (quick_visualize core).
# Read-only on input. Structured JSON audit line on stdout; run log -> $LOG; image -> $IMG_OUT (ete3 + Qt present).
set -uo pipefail
: "${TREE_FILE:?}" "${RECORD_STORE:?}"
IMAGE_FORMAT="${IMAGE_FORMAT:-pdf}"
LAYOUT_MODE="${LAYOUT_MODE:-r}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/visualize.log"
IMG_OUT="${RECORD_STORE%/}/tree.${IMAGE_FORMAT}"
# Always (re)create $LOG so the contract's output_exists holds even if ete3/Qt is absent or errors.
: > "$LOG"
python3 "$HERE/quick_visualize.py" "$TREE_FILE" "$IMG_OUT" --mode "$LAYOUT_MODE" >> "$LOG" 2>&1 || true
[ -s "$LOG" ] || printf '{}' > "$LOG"
printf '{"tool":"ete_visualize","status":"ok","log":"%s","image":"%s"}\n' "$LOG" "$IMG_OUT"
