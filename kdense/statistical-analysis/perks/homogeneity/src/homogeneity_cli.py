#!/usr/bin/env python3
"""
homogeneity_cli — thin CLI over assumption_checks.check_homogeneity_of_variance.

Reads a CSV, runs Levene's test for equality of variance across groups, writes a
JSON report and a box-plot / variance-bar PNG. Pure diagnostic, read-only.

Env vars (set by the porter):
  DATA_CSV    path to input CSV
  VALUE_COL   numeric column
  GROUP_COL   grouping column
  ALPHA       significance level (default 0.05)
  OUT         output JSON report path
  FIG         output figure PNG path
"""
import json
import os
import sys

import matplotlib
matplotlib.use("Agg")  # headless: never call plt.show()
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# sibling import of the vendored core (PYTHONPATH set by the porter)
from assumption_checks import check_homogeneity_of_variance


def main() -> int:
    data_csv = os.environ["DATA_CSV"]
    value_col = os.environ["VALUE_COL"]
    group_col = os.environ["GROUP_COL"]
    alpha = float(os.environ.get("ALPHA", "0.05"))
    out = os.environ["OUT"]
    fig = os.environ.get("FIG", "")

    df = pd.read_csv(data_csv)

    # plot=False so the vendored core never blocks on plt.show(); we render our own figure.
    result = check_homogeneity_of_variance(df, value_col, group_col, alpha=alpha, plot=False)
    # coerce numpy scalars to native Python so the JSON report is clean (bool not "True")
    result["statistic"] = float(result["statistic"])
    result["p_value"] = float(result["p_value"])
    result["is_homogeneous"] = bool(result["is_homogeneous"])
    result["variance_ratio"] = float(result["variance_ratio"])

    if fig:
        groups = [g[value_col].values for _, g in df.groupby(group_col)]
        names = list(df[group_col].unique())
        variances = [float(np.var(g, ddof=1)) for g in groups]
        f, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
        df.boxplot(column=value_col, by=group_col, ax=ax1)
        ax1.set_title("Box Plots by Group")
        ax2.bar(range(len(variances)), variances, color="steelblue", edgecolor="black")
        ax2.set_xticks(range(len(variances)))
        ax2.set_xticklabels(names, rotation=45)
        ax2.set_title("Variance by Group")
        f.suptitle("")
        f.tight_layout()
        f.savefig(fig, dpi=80)
        plt.close(f)
        result["figure"] = fig

    with open(out, "w") as fh:
        json.dump(result, fh, default=str, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
