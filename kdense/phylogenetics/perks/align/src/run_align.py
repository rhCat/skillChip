#!/usr/bin/env python3
"""run_align — thin runner around the vendored phylogenetic_analysis.run_mafft.

Sibling import: imports the UNCHANGED vendored core (phylogenetic_analysis.py)
and invokes exactly its MAFFT alignment step. Env -> arg translation is done by
the porter (mafft_align.sh), which passes positional args:

    run_align.py <INPUT_FASTA> <OUTPUT_FASTA> <THREADS> <METHOD>
"""
import sys
import phylogenetic_analysis as core


def main():
    input_fasta = sys.argv[1]
    output_fasta = sys.argv[2]
    n_threads = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else 4
    method = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else "auto"
    core.run_mafft(input_fasta, output_fasta, n_threads=n_threads, method=method)


if __name__ == "__main__":
    main()
