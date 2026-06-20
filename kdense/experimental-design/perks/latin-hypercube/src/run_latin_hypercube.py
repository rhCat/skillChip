#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call doe_designs.latin_hypercube, write CSV.

Spec keys: factors (dict {name: [low, high]}, required), n_samples (int, required),
criterion (str, default "maximin"), seed (int), randomize (bool, default false).
Writes the space-filling Latin-hypercube sample in real units to argv[2] as CSV.
"""
import json
import sys

from doe_designs import latin_hypercube

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

factors = {k: tuple(v) for k, v in spec["factors"].items()}
n_samples = int(spec["n_samples"])
criterion = spec.get("criterion", "maximin")
seed = int(spec.get("seed", 0))
randomize = bool(spec.get("randomize", False))

df = latin_hypercube(factors, n_samples, criterion=criterion, seed=seed,
                     randomize=randomize)
df.to_csv(out_path, index=False)
