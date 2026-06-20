#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call doe_designs.fractional_factorial, write CSV.

Spec keys: factors (dict {name: [low, high]}, required), generator (str — pyDOE3
Yates notation, e.g. "a b c abc", required), randomize (bool, default true),
seed (int). Writes the 2^(k-p) fractional design in real units to argv[2] as CSV.
"""
import json
import sys

from doe_designs import fractional_factorial

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

factors = {k: tuple(v) for k, v in spec["factors"].items()}
generator = spec["generator"]
randomize = bool(spec.get("randomize", True))
seed = int(spec.get("seed", 0))

df = fractional_factorial(factors, generator, randomize=randomize, seed=seed)
df.to_csv(out_path, index=False)
