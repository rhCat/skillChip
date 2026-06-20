#!/usr/bin/env python3
"""run_iqtree — thin runner around the vendored phylogenetic_analysis.run_iqtree.

Sibling import: imports the UNCHANGED vendored core (phylogenetic_analysis.py)
and invokes exactly its IQ-TREE 2 inference step. Env -> arg translation is done
by the porter (iqtree_infer.sh), which passes positional args:

    run_iqtree.py <ALIGNED_FASTA> <PREFIX> <SEQ_TYPE> <BOOTSTRAP> <THREADS> [OUTGROUP]
"""
import sys
import phylogenetic_analysis as core


def main():
    aligned_fasta = sys.argv[1]
    prefix = sys.argv[2]
    seq_type = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else "nt"
    bootstrap = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4] else 1000
    n_threads = int(sys.argv[5]) if len(sys.argv) > 5 and sys.argv[5] else 4
    outgroup = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] else None
    core.run_iqtree(aligned_fasta, prefix, seq_type=seq_type,
                    bootstrap=bootstrap, n_threads=n_threads, outgroup=outgroup)


if __name__ == "__main__":
    main()
