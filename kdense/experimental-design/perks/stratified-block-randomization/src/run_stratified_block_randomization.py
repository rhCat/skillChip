#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call randomization.stratified_block_randomization, write CSV.

Spec keys: strata (dict {label: n} OR list[str] of per-unit labels, required),
arms (list[str]), block_size (int), ratio (list[int]), seed (int). Writes the
stratified permuted-block allocation schedule to argv[2] as CSV.
"""
import json
import sys

from randomization import stratified_block_randomization

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

strata = spec["strata"]
arms = spec.get("arms", ["treatment", "control"])
block_size = spec.get("block_size")
ratio = spec.get("ratio")
seed = int(spec.get("seed", 0))

df = stratified_block_randomization(strata, arms=arms, block_size=block_size,
                                    ratio=ratio, seed=seed)
df.to_csv(out_path, index=False)
