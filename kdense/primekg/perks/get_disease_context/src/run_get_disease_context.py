#!/usr/bin/env python3
"""
run_get_disease_context — thin CLI over the vendored query_primekg.get_disease_context core.

Resolves a disease by name, then summarizes its local PrimeKG neighborhood into
associated genes, drugs, phenotypes and related diseases, and writes the summary
as JSON.

env -> arg translation (set by the porter):
  PRIMEKG_CSV    absolute path to the PrimeKG kg.csv edge list (overrides the
                 vendored core's hard-coded DATA_PATH)
  DISEASE_NAME   disease name to look up (e.g. Alzheimer's disease)

Writes ${RECORD_STORE}/disease_context.json . Read-only.
"""
import json
import os
import sys

import query_primekg  # vendored UNCHANGED alongside this file


def main():
    csv = os.environ.get("PRIMEKG_CSV", "").strip()
    if csv:
        query_primekg.DATA_PATH = csv
    disease_name = os.environ.get("DISEASE_NAME", "").strip()

    context = query_primekg.get_disease_context(disease_name)
    out = {
        "tool": "get_disease_context",
        "disease_name": disease_name,
        "context": context,
    }
    json.dump(out, sys.stdout, default=str)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
