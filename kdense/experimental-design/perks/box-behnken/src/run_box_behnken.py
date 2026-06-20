#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call doe_designs.box_behnken, write CSV.

Spec keys: factors (dict {name: [low, high]}, required, >=3 factors), center (int,
default 1), randomize (bool, default true), seed (int). Writes the Box-Behnken
response-surface design in real units to argv[2] as CSV.
"""
import json
import sys

from doe_designs import box_behnken

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

factors = {k: tuple(v) for k, v in spec["factors"].items()}
center = int(spec.get("center", 1))
randomize = bool(spec.get("randomize", True))
seed = int(spec.get("seed", 0))

df = box_behnken(factors, center=center, randomize=randomize, seed=seed)
df.to_csv(out_path, index=False)
