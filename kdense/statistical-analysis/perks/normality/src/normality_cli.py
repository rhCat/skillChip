#!/usr/bin/env python3
"""
normality_cli — thin CLI over assumption_checks.check_normality.

Reads a CSV, runs the Shapiro-Wilk normality test on one numeric column, writes a
JSON report and a Q-Q / histogram PNG. Pure diagnostic, read-only.

Env vars (set by the porter):
  DATA_CSV    path to input CSV
  VALUE_COL   numeric column to test
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
from scipy import stats

# sibling import of the vendored core (PYTHONPATH set by the porter)
from assumption_checks import check_normality


def main() -> int:
    data_csv = os.environ["DATA_CSV"]
    value_col = os.environ["VALUE_COL"]
    alpha = float(os.environ.get("ALPHA", "0.05"))
    out = os.environ["OUT"]
    fig = os.environ.get("FIG", "")

    df = pd.read_csv(data_csv)
    series = df[value_col].dropna()

    # plot=False so the vendored core never blocks on plt.show(); we render our own figure.
    result = check_normality(series, name=value_col, alpha=alpha, plot=False)
    # coerce numpy scalars to native Python so the JSON report is clean (bool not "True")
    result["statistic"] = float(result["statistic"])
    result["p_value"] = float(result["p_value"])
    result["is_normal"] = bool(result["is_normal"])
    result["n"] = int(result["n"])

    if fig:
        arr = np.asarray(series, dtype=float)
        arr = arr[~np.isnan(arr)]
        f, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
        stats.probplot(arr, dist="norm", plot=ax1)
        ax1.set_title(f"Q-Q Plot: {value_col}")
        ax2.hist(arr, bins="auto", density=True, alpha=0.7,
                 color="steelblue", edgecolor="black")
        ax2.set_title(f"Histogram: {value_col}")
        f.tight_layout()
        f.savefig(fig, dpi=80)
        plt.close(f)
        result["figure"] = fig

    with open(out, "w") as fh:
        json.dump(result, fh, default=str, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
