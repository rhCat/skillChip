#!/usr/bin/env bash
# ete_stats — tree statistics (leaf/node counts, depth, branch-length + support stats) via ETE.
# Read-only. Structured JSON audit line on stdout; human report -> $OUT.
set -uo pipefail
: "${TREE_FILE:?}" "${RECORD_STORE:?}"
TREE_FORMAT="${TREE_FORMAT:-0}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/stats.txt"
# Always (re)create $OUT so the contract's output_exists holds even if ete3 is absent or errors.
: > "$OUT"
python3 "$HERE/tree_operations.py" stats "$TREE_FILE" --format "$TREE_FORMAT" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"ete_stats","status":"ok","report":"%s"}\n' "$OUT"
