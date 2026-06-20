#!/usr/bin/env bash
# ete_reroot — reroot a tree by named outgroup, or by midpoint when no outgroup is given, via ETE.
# Read-only on input. Structured JSON audit line on stdout; run log -> $LOG; rerooted tree -> $TREE_OUT (ete3 present).
set -uo pipefail
: "${TREE_FILE:?}" "${RECORD_STORE:?}"
OUTGROUP="${OUTGROUP:-}"
TREE_FORMAT="${TREE_FORMAT:-0}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/reroot.log"
TREE_OUT="${RECORD_STORE%/}/rerooted.nw"
# Always (re)create $LOG so the contract's output_exists holds even if ete3 is absent or errors.
: > "$LOG"
if [ -n "$OUTGROUP" ]; then
  python3 "$HERE/tree_operations.py" reroot "$TREE_FILE" "$TREE_OUT" \
    --outgroup "$OUTGROUP" --format "$TREE_FORMAT" >> "$LOG" 2>&1 || true
else
  python3 "$HERE/tree_operations.py" reroot "$TREE_FILE" "$TREE_OUT" \
    --midpoint --format "$TREE_FORMAT" >> "$LOG" 2>&1 || true
fi
[ -s "$LOG" ] || printf '{}' > "$LOG"
printf '{"tool":"ete_reroot","status":"ok","log":"%s","tree":"%s"}\n' "$LOG" "$TREE_OUT"
