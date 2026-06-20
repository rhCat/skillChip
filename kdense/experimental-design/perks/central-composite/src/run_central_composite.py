#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call doe_designs.central_composite, write CSV.

Spec keys: factors (dict {name: [low, high]}, required), center ([int, int]),
alpha (str, default "orthogonal"), face (str, default "circumscribed"),
randomize (bool, default true), seed (int). Writes the central-composite
response-surface design in real units to argv[2] as CSV.
"""
import json
import sys

from doe_designs import central_composite

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

factors = {k: tuple(v) for k, v in spec["factors"].items()}
center = tuple(spec.get("center", (0, 1)))
alpha = spec.get("alpha", "orthogonal")
face = spec.get("face", "circumscribed")
randomize = bool(spec.get("randomize", True))
seed = int(spec.get("seed", 0))

df = central_composite(factors, center=center, alpha=alpha, face=face,
                       randomize=randomize, seed=seed)
df.to_csv(out_path, index=False)
