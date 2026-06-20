#!/usr/bin/env python3
"""run_fasttree — thin runner around the vendored phylogenetic_analysis.run_fasttree.

Sibling import: imports the UNCHANGED vendored core (phylogenetic_analysis.py)
and invokes exactly its FastTree inference step. Env -> arg translation is done
by the porter (fasttree_infer.sh), which passes positional args:

    run_fasttree.py <ALIGNED_FASTA> <OUTPUT_TREE> <SEQ_TYPE>
"""
import sys
import phylogenetic_analysis as core


def main():
    aligned_fasta = sys.argv[1]
    output_tree = sys.argv[2]
    seq_type = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else "nt"
    core.run_fasttree(aligned_fasta, output_tree, seq_type=seq_type)


if __name__ == "__main__":
    main()
