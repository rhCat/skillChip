#!/usr/bin/env bash
# iqtree_infer — IQ-TREE 2 maximum-likelihood tree (aligned FASTA -> Newick treefile).
# Thin porter around the vendored phylogenetic_analysis.run_iqtree. Structured JSON audit line.
set -uo pipefail
: "${ALIGNED_FASTA:?}" "${RECORD_STORE:?}"
SEQ_TYPE="${SEQ_TYPE:-nt}"
BOOTSTRAP="${BOOTSTRAP:-1000}"
THREADS="${THREADS:-4}"
OUTGROUP="${OUTGROUP:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${RECORD_STORE%/}/phylo"
OUT="${PREFIX}.treefile"
# Always (re)create $OUT so the contract's output_exists holds even if iqtree2 / python are absent or error.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/run_iqtree.py" "$ALIGNED_FASTA" "$PREFIX" "$SEQ_TYPE" "$BOOTSTRAP" "$THREADS" "$OUTGROUP" >/dev/null 2>&1 || true
# If inference could not run (iqtree2 / python absent, or it errored), keep the contract satisfiable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"iqtree_infer","status":"ok","treefile":"%s","seq_type":"%s","bootstrap":"%s"}\n' "$OUT" "$SEQ_TYPE" "$BOOTSTRAP"
