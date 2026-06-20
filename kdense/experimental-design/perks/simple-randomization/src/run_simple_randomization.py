#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call randomization.simple_randomization, write CSV.

Spec keys (all optional except n): n (int, required), arms (list[str]),
ratio (list[int]), seed (int). Writes the allocation schedule to argv[2] as CSV.
"""
import json
import sys

from randomization import simple_randomization

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

n = int(spec["n"])
arms = spec.get("arms", ["treatment", "control"])
ratio = spec.get("ratio")
seed = int(spec.get("seed", 0))

df = simple_randomization(n, arms=arms, ratio=ratio, seed=seed)
df.to_csv(out_path, index=False)
