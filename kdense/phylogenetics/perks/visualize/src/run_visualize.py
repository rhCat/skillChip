#!/usr/bin/env python3
"""run_visualize — thin runner around the vendored phylogenetic_analysis.visualize_tree.

Sibling import: imports the UNCHANGED vendored core (phylogenetic_analysis.py)
and invokes exactly its ETE3 visualization step. The core renders a PNG (with a
Newick fallback if rendering fails) and skips gracefully if ete3 is absent. Env ->
arg translation is done by the porter (tree_visualize.sh), which passes:

    run_visualize.py <TREE_FILE> <OUTPUT_PNG> [OUTGROUP]
"""
import sys
import phylogenetic_analysis as core


def main():
    tree_file = sys.argv[1]
    output_png = sys.argv[2]
    outgroup = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else None
    core.visualize_tree(tree_file, output_png, outgroup=outgroup)


if __name__ == "__main__":
    main()
