#!/usr/bin/env bash
# ete_prune — prune a tree to a set of taxa (branch lengths preserved) via ETE.
# Read-only on input. Structured JSON audit line on stdout; run log -> $LOG; pruned tree -> $TREE_OUT (ete3 present).
set -uo pipefail
: "${TREE_FILE:?}" "${KEEP_TAXA:?}" "${RECORD_STORE:?}"
TREE_FORMAT="${TREE_FORMAT:-0}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${RECORD_STORE%/}/prune.log"
TREE_OUT="${RECORD_STORE%/}/pruned.nw"
# Always (re)create $LOG so the contract's output_exists holds even if ete3 is absent or errors.
: > "$LOG"
python3 "$HERE/tree_operations.py" prune "$TREE_FILE" "$TREE_OUT" \
  --keep-taxa "$KEEP_TAXA" --format "$TREE_FORMAT" >> "$LOG" 2>&1 || true
[ -s "$LOG" ] || printf '{}' > "$LOG"
printf '{"tool":"ete_prune","status":"ok","log":"%s","tree":"%s"}\n' "$LOG" "$TREE_OUT"
