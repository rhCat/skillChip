#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call doe_designs.full_factorial, write CSV.

Spec keys: factors (dict {name: [level, ...]}, required — explicit level lists),
randomize (bool, default true), seed (int). Writes the full-factorial design in
real units to argv[2] as CSV.
"""
import json
import sys

from doe_designs import full_factorial

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

factors = spec["factors"]
randomize = bool(spec.get("randomize", True))
seed = int(spec.get("seed", 0))

df = full_factorial(factors, randomize=randomize, seed=seed)
df.to_csv(out_path, index=False)
