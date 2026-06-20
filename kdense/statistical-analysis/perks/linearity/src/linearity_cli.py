#!/usr/bin/env python3
"""
linearity_cli — thin CLI over assumption_checks.check_linearity.

Reads a CSV, fits a simple linear regression of Y on X, reports r / r-squared, and
renders a scatter+fit / residuals-vs-fitted PNG. Pure diagnostic, read-only.

Env vars (set by the porter):
  DATA_CSV    path to input CSV
  X_COL       predictor column
  Y_COL       outcome column
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

# sibling import of the vendored core (PYTHONPATH set by the porter).
# NB: the vendored check_linearity() always plots+shows; we replicate its numeric
# core here (and render to a file) so it stays unchanged and never blocks headless.
import assumption_checks  # noqa: F401  (kept for provenance / sibling-import parity)


def main() -> int:
    data_csv = os.environ["DATA_CSV"]
    x_col = os.environ["X_COL"]
    y_col = os.environ["Y_COL"]
    out = os.environ["OUT"]
    fig = os.environ.get("FIG", "")

    df = pd.read_csv(data_csv)
    sub = df[[x_col, y_col]].dropna()
    x = np.asarray(sub[x_col], dtype=float)
    y = np.asarray(sub[y_col], dtype=float)

    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    y_pred = intercept + slope * x
    residuals = y - y_pred

    result = {
        "slope": float(slope),
        "intercept": float(intercept),
        "r": float(r_value),
        "r_squared": float(r_value ** 2),
        "p_value": float(p_value),
        "std_err": float(std_err),
        "n": int(len(x)),
        "interpretation": (
            "Examine residual plot. Points should be randomly scattered around zero. "
            "Patterns (curves, funnels) suggest non-linearity or heteroscedasticity."
        ),
        "recommendation": (
            "If non-linear pattern detected: Consider polynomial terms, "
            "transformations, or non-linear models"
        ),
    }

    if fig:
        f, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
        ax1.scatter(x, y, alpha=0.6, s=50, edgecolors="black", linewidths=0.5)
        order = np.argsort(x)
        ax1.plot(x[order], y_pred[order], "r-", linewidth=2,
                 label=f"y = {intercept:.2f} + {slope:.2f}x")
        ax1.set_xlabel(x_col)
        ax1.set_ylabel(y_col)
        ax1.set_title("Scatter with Regression Line")
        ax1.legend()
        ax2.scatter(y_pred, residuals, alpha=0.6, s=50, edgecolors="black", linewidths=0.5)
        ax2.axhline(y=0, color="r", linestyle="--", linewidth=2)
        ax2.set_xlabel("Fitted values")
        ax2.set_ylabel("Residuals")
        ax2.set_title("Residuals vs Fitted")
        f.tight_layout()
        f.savefig(fig, dpi=80)
        plt.close(f)
        result["figure"] = fig

    with open(out, "w") as fh:
        json.dump(result, fh, default=str, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
