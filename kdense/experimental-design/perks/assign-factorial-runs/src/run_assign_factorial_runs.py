#!/usr/bin/env python3
"""Thin runner: read a JSON spec, call randomization.assign_factorial_runs, write CSV.

Spec keys (provide exactly one of rows / design_csv): rows (list[dict] of design
rows), design_csv (path to an existing CSV of design rows), seed (int). Writes the
design with a randomized 'run_order' column, sorted by it, to argv[2] as CSV.
"""
import json
import sys

import pandas as pd

from randomization import assign_factorial_runs

spec_path, out_path = sys.argv[1], sys.argv[2]
with open(spec_path) as fh:
    spec = json.load(fh)

if "rows" in spec:
    design_df = pd.DataFrame(spec["rows"])
elif "design_csv" in spec:
    design_df = pd.read_csv(spec["design_csv"])
else:
    raise ValueError("spec must provide either 'rows' or 'design_csv'")

seed = int(spec.get("seed", 0))
df = assign_factorial_runs(design_df, seed=seed)
df.to_csv(out_path, index=False)
