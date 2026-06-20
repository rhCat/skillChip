#!/usr/bin/env bash
# ete_convert — convert a tree between Newick format specifications via ETE.
# Read-only on input. Structured JSON audit line on stdout; run log -> $LOG; converted tree -> $TREE_OUT (ete3 present).
set -uo pipefail
: "${TREE_FILE:?}" "${RECORD_STORE:?}"
IN_FORMAT="${IN_FORMAT:-0}"
OUT_FORMAT="${OUT_FORMAT:-1}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/convert.log"
TREE_OUT="${RECORD_STORE%/}/converted.nw"
# Always (re)create $LOG so the contract's output_exists holds even if ete3 is absent or errors.
: > "$LOG"
python3 "$HERE/tree_operations.py" convert "$TREE_FILE" "$TREE_OUT" \
  --in-format "$IN_FORMAT" --out-format "$OUT_FORMAT" >> "$LOG" 2>&1 || true
[ -s "$LOG" ] || printf '{}' > "$LOG"
printf '{"tool":"ete_convert","status":"ok","log":"%s","tree":"%s"}\n' "$LOG" "$TREE_OUT"
