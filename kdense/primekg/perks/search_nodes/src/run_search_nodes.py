#!/usr/bin/env python3
"""
run_search_nodes — thin CLI over the vendored query_primekg.search_nodes core.

Substring-searches PrimeKG nodes (the union of x_* and y_* columns of the edge
list) by name, optionally filtered by node type, and writes the matches as JSON.

env -> arg translation (set by the porter):
  PRIMEKG_CSV   absolute path to the PrimeKG kg.csv edge list  (overrides the
                vendored core's hard-coded DATA_PATH)
  NAME_QUERY    substring matched case-insensitively against node names
  NODE_TYPE     optional node-type filter (e.g. disease | drug | gene/protein)

Writes ${RECORD_STORE}/search_nodes.json . Read-only.
"""
import json
import os
import sys

import query_primekg  # vendored UNCHANGED alongside this file


def main():
    csv = os.environ.get("PRIMEKG_CSV", "").strip()
    if csv:
        query_primekg.DATA_PATH = csv  # redirect the core off its hard-coded path
    name_query = os.environ.get("NAME_QUERY", "").strip()
    node_type = os.environ.get("NODE_TYPE", "").strip() or None

    results = query_primekg.search_nodes(name_query, node_type=node_type)
    out = {
        "tool": "search_nodes",
        "name_query": name_query,
        "node_type": node_type,
        "count": len(results),
        "results": results,
    }
    json.dump(out, sys.stdout, default=str)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
