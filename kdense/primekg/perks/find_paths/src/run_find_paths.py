#!/usr/bin/env python3
"""
run_find_paths — thin CLI over the vendored query_primekg.find_paths core.

Finds direct (depth-1) edges that connect two PrimeKG nodes in either direction
— e.g. a drug and a disease, surfacing a candidate repurposing edge — and
writes the connecting edges as JSON.

env -> arg translation (set by the porter):
  PRIMEKG_CSV     absolute path to the PrimeKG kg.csv edge list (overrides the
                  vendored core's hard-coded DATA_PATH)
  START_NODE_ID   the start node id (e.g. a drug id CHEMBL502)
  END_NODE_ID     the end node id (e.g. a disease id EFO_0000249)
  MAX_DEPTH       optional max path depth (default 2; the core resolves depth-1
                  edges, depth-2 is a documented MVP stub)

Writes ${RECORD_STORE}/find_paths.json . Read-only.
"""
import json
import os
import sys

import query_primekg  # vendored UNCHANGED alongside this file


def main():
    csv = os.environ.get("PRIMEKG_CSV", "").strip()
    if csv:
        query_primekg.DATA_PATH = csv
    start_node_id = os.environ.get("START_NODE_ID", "").strip()
    end_node_id = os.environ.get("END_NODE_ID", "").strip()
    try:
        max_depth = int(os.environ.get("MAX_DEPTH", "2").strip() or "2")
    except ValueError:
        max_depth = 2

    paths = query_primekg.find_paths(start_node_id, end_node_id, max_depth=max_depth)
    out = {
        "tool": "find_paths",
        "start_node_id": start_node_id,
        "end_node_id": end_node_id,
        "max_depth": max_depth,
        "count": len(paths),
        "paths": paths,
    }
    json.dump(out, sys.stdout, default=str)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
