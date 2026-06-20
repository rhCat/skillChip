#!/usr/bin/env python3
"""
run_get_neighbors — thin CLI over the vendored query_primekg.get_neighbors core.

Lists every direct neighbor of a PrimeKG node (scanning both the x_* and y_*
sides of the edge list), optionally filtered to a single relation type, and
writes the neighbors as JSON.

env -> arg translation (set by the porter):
  PRIMEKG_CSV     absolute path to the PrimeKG kg.csv edge list (overrides the
                  vendored core's hard-coded DATA_PATH)
  NODE_ID         the node id whose neighbors to list (e.g. EFO_0000249, 348)
  RELATION_TYPE   optional relation filter (e.g. disease_gene, drug_protein)

Writes ${RECORD_STORE}/get_neighbors.json . Read-only.
"""
import json
import os
import sys

import query_primekg  # vendored UNCHANGED alongside this file


def main():
    csv = os.environ.get("PRIMEKG_CSV", "").strip()
    if csv:
        query_primekg.DATA_PATH = csv
    node_id = os.environ.get("NODE_ID", "").strip()
    relation_type = os.environ.get("RELATION_TYPE", "").strip() or None

    neighbors = query_primekg.get_neighbors(node_id, relation_type=relation_type)
    out = {
        "tool": "get_neighbors",
        "node_id": node_id,
        "relation_type": relation_type,
        "count": len(neighbors),
        "neighbors": neighbors,
    }
    json.dump(out, sys.stdout, default=str)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
