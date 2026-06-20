#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call randomization.cluster_randomization, write CSV.

Spec keys: clusters (list[str] of cluster ids OR int count, required), arms (list[str]),
ratio (list[int]), block_size (int), seed (int). Writes one row per cluster to
argv[2] as CSV.
"""
import json
import sys

from randomization import cluster_randomization

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

clusters = spec["clusters"]
arms = spec.get("arms", ["treatment", "control"])
ratio = spec.get("ratio")
block_size = spec.get("block_size")
seed = int(spec.get("seed", 0))

df = cluster_randomization(clusters, arms=arms, ratio=ratio,
                           block_size=block_size, seed=seed)
df.to_csv(out_path, index=False)
