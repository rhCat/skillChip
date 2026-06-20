#!/usr/bin/env python3
"""
assumptions_cli — thin CLI over the assumption_checks comprehensive workflow.

Reads a CSV and runs the full assumption battery for one numeric column: outlier
detection, normality (overall, or per-group when GROUP_COL is set), and — when
grouped — Levene's homogeneity-of-variance test. Writes a single combined JSON
report. Pure diagnostic, read-only.

Env vars (set by the porter):
  DATA_CSV    path to input CSV
  VALUE_COL   numeric column
  GROUP_COL   grouping column (optional; empty = ungrouped)
  ALPHA       significance level (default 0.05)
  OUT         output JSON report path
"""
import json
import os
import sys

import matplotlib
matplotlib.use("Agg")  # headless: never call plt.show()
import pandas as pd

# sibling import of the vendored core (PYTHONPATH set by the porter). We compose the
# same battery as comprehensive_assumption_check() but with plot=False so nothing
# blocks headless, while keeping the vendored module byte-for-byte unchanged.
from assumption_checks import (
    detect_outliers,
    check_normality,
    check_normality_per_group,
    check_homogeneity_of_variance,
)


def main() -> int:
    data_csv = os.environ["DATA_CSV"]
    value_col = os.environ["VALUE_COL"]
    group_col = os.environ.get("GROUP_COL", "").strip() or None
    alpha = float(os.environ.get("ALPHA", "0.05"))
    out = os.environ["OUT"]

    df = pd.read_csv(data_csv)
    results = {}

    results["outliers"] = detect_outliers(
        df[value_col].dropna(), name=value_col, method="iqr", plot=False
    )
    results["outliers"]["outlier_indices"] = list(map(int, results["outliers"]["outlier_indices"]))
    results["outliers"]["outlier_values"] = list(map(float, results["outliers"]["outlier_values"]))

    if group_col is not None:
        norm = check_normality_per_group(df, value_col, group_col, alpha=alpha, plot=False)
        results["normality_per_group"] = norm.to_dict(orient="records")
        all_normal = norm["Normal"].eq("Yes").all()
        homog = check_homogeneity_of_variance(df, value_col, group_col, alpha=alpha, plot=False)
        results["homogeneity"] = homog
        results["summary"] = {
            "all_groups_normal": bool(all_normal),
            "homogeneous_variance": bool(homog["is_homogeneous"]),
            "all_assumptions_met": bool(all_normal and homog["is_homogeneous"]),
        }
    else:
        norm = check_normality(df[value_col].dropna(), name=value_col, alpha=alpha, plot=False)
        results["normality"] = norm
        results["summary"] = {"normality_met": bool(norm["is_normal"])}

    with open(out, "w") as fh:
        json.dump(results, fh, default=str, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
