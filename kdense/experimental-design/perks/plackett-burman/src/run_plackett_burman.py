#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call doe_designs.plackett_burman, write CSV.

Spec keys: factors (dict {name: [low, high]}, required), randomize (bool, default
true), seed (int). Writes the Plackett-Burman screening design in real units to
argv[2] as CSV.
"""
import json
import sys

from doe_designs import plackett_burman

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

factors = {k: tuple(v) for k, v in spec["factors"].items()}
randomize = bool(spec.get("randomize", True))
seed = int(spec.get("seed", 0))

df = plackett_burman(factors, randomize=randomize, seed=seed)
df.to_csv(out_path, index=False)
