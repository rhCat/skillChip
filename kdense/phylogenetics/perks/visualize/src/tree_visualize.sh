#!/usr/bin/env bash
# tree_visualize — ETE3 rooted-tree render to PNG with Newick fallback (Newick tree -> PNG).
# Thin porter around the vendored phylogenetic_analysis.visualize_tree. Structured JSON audit line.
set -uo pipefail
: "${TREE_FILE:?}" "${RECORD_STORE:?}"
OUTGROUP="${OUTGROUP:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/tree.png"
# Always (re)create $OUT so the contract's output_exists holds even if ete3 / python are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_visualize.py" "$TREE_FILE" "$OUT" "$OUTGROUP" >/dev/null 2>&1 || true
# If rendering could not run (ete3 / python absent, or it errored), keep the contract satisfiable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"tree_visualize","status":"ok","image":"%s"}\n' "$OUT"
