#!/usr/bin/env python3
"""
outliers_cli — thin CLI over assumption_checks.detect_outliers.

Reads a CSV, flags outliers in one numeric column by IQR or z-score, writes a JSON
report and a box-plot / scatter PNG. Pure diagnostic, read-only.

Env vars (set by the porter):
  DATA_CSV    path to input CSV
  VALUE_COL   numeric column
  METHOD      'iqr' or 'zscore' (default 'iqr')
  THRESHOLD   detection threshold (default 1.5)
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
from assumption_checks import detect_outliers


def main() -> int:
    data_csv = os.environ["DATA_CSV"]
    value_col = os.environ["VALUE_COL"]
    method = os.environ.get("METHOD", "iqr")
    threshold = float(os.environ.get("THRESHOLD", "1.5"))
    out = os.environ["OUT"]
    fig = os.environ.get("FIG", "")

    df = pd.read_csv(data_csv)
    series = df[value_col].dropna()

    # plot=False so the vendored core never blocks on plt.show(); we render our own figure.
    result = detect_outliers(series, name=value_col, method=method,
                             threshold=threshold, plot=False)

    # coerce numpy scalars/arrays to native Python so the JSON report is clean
    result["outlier_indices"] = np.asarray(result["outlier_indices"]).tolist()
    result["outlier_values"] = np.asarray(result["outlier_values"]).tolist()
    result["n_outliers"] = int(result["n_outliers"])
    result["pct_outliers"] = float(result["pct_outliers"])
    result["threshold"] = float(result["threshold"])
    result["lower_bound"] = float(result["lower_bound"])
    result["upper_bound"] = float(result["upper_bound"])

    if fig:
        arr = np.asarray(series, dtype=float)
        arr = arr[~np.isnan(arr)]
        lower = result["lower_bound"]
        upper = result["upper_bound"]
        mask = (arr < lower) | (arr > upper)
        f, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
        bp = ax1.boxplot(arr, patch_artist=True)
        bp["boxes"][0].set_facecolor("steelblue")
        ax1.set_title(f"Box Plot: {value_col}")
        xc = np.arange(len(arr))
        ax2.scatter(xc[~mask], arr[~mask], alpha=0.6, s=50, color="steelblue",
                    label="Normal", edgecolors="black", linewidths=0.5)
        if mask.any():
            ax2.scatter(xc[mask], arr[mask], alpha=0.8, s=100, color="red",
                        label="Outliers", marker="D", edgecolors="black", linewidths=0.5)
        ax2.axhline(y=lower, color="orange", linestyle="--", linewidth=1.5, label="Bounds")
        ax2.axhline(y=upper, color="orange", linestyle="--", linewidth=1.5)
        ax2.set_title(f"Outlier Detection: {value_col}")
        ax2.legend()
        f.tight_layout()
        f.savefig(fig, dpi=80)
        plt.close(f)
        result["figure"] = fig

    with open(out, "w") as fh:
        json.dump(result, fh, default=str, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
