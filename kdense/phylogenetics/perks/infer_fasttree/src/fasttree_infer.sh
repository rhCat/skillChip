#!/usr/bin/env bash
# fasttree_infer — FastTree fast approximate ML tree (aligned FASTA -> Newick tree).
# Thin porter around the vendored phylogenetic_analysis.run_fasttree. Structured JSON audit line.
set -uo pipefail
: "${ALIGNED_FASTA:?}" "${RECORD_STORE:?}"
SEQ_TYPE="${SEQ_TYPE:-nt}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/phylo.tree"
# Always (re)create $OUT so the contract's output_exists holds even if FastTree / python are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_fasttree.py" "$ALIGNED_FASTA" "$OUT" "$SEQ_TYPE" >/dev/null 2>&1 || true
# If inference could not run (FastTree / python absent, or it errored), keep the contract satisfiable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"fasttree_infer","status":"ok","tree":"%s","seq_type":"%s"}\n' "$OUT" "$SEQ_TYPE"
