#!/usr/bin/env python3
"""run_tree_summary — thin runner around the vendored phylogenetic_analysis.tree_summary.

Sibling import: imports the UNCHANGED vendored core (phylogenetic_analysis.py)
and invokes exactly its tree-summary step (ETE3). Writes the returned stats dict
as JSON to the output path. Env -> arg translation is done by the porter
(tree_summary.sh), which passes positional args:

    run_tree_summary.py <TREE_FILE> <OUTPUT_JSON>

Requires ete3; if absent the core returns {} and we emit {} (graceful, offline).
"""
import json
import sys
import phylogenetic_analysis as core


def main():
    tree_file = sys.argv[1]
    output_json = sys.argv[2]
    stats = core.tree_summary(tree_file)
    with open(output_json, "w") as fh:
        json.dump(stats if stats else {}, fh, indent=2)


if __name__ == "__main__":
    main()
