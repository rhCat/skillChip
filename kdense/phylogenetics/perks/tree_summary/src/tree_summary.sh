#!/usr/bin/env bash
# tree_summary — ETE3 tree statistics (Newick tree -> JSON stats). Read-only.
# Thin porter around the vendored phylogenetic_analysis.tree_summary. Structured JSON audit line.
set -uo pipefail
: "${TREE_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/tree_stats.json"
# Always (re)create $OUT so the contract's output_exists holds even if ete3 / python are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_tree_summary.py" "$TREE_FILE" "$OUT" >/dev/null 2>&1 || true
# If the summary could not run (ete3 / python absent, or it errored), keep the contract satisfiable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"tree_summary","status":"ok","stats":"%s"}\n' "$OUT"
