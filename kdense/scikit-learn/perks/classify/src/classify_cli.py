#!/usr/bin/env python3
"""classify_cli — thin CLI driver around the vendored classification_pipeline.py core.

Reads a CSV (last column = target, all others = features), runs the vendored
train_and_evaluate_model (preprocess -> CV model comparison -> GridSearchCV tune ->
test metrics + feature importances), and writes the metric summary as JSON.

env in:  DATA_CSV (required), TARGET_COL (optional name; default = last column),
         TEST_SIZE (optional float; default 0.2), OUT (required output path)
out:     JSON {status, n_samples, n_features, classes, metrics, ...}

The heavy dependency is scikit-learn; if it (or pandas/numpy) is missing this driver
exits non-zero and the porter degrades to a graceful {} -> note line.
"""
import json
import os
import sys


def main():
    out = os.environ["OUT"]
    data_csv = os.environ["DATA_CSV"]
    target_col = os.environ.get("TARGET_COL", "").strip()
    test_size = float(os.environ.get("TEST_SIZE", "0.2"))

    import numpy as np
    import pandas as pd

    # Import the vendored core (sits next to this file).
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from classification_pipeline import train_and_evaluate_model

    df = pd.read_csv(data_csv)
    if df.shape[1] < 2:
        raise ValueError("DATA_CSV needs >=1 feature column and a target column")

    if target_col and target_col in df.columns:
        y = df[target_col]
        X = df.drop(columns=[target_col])
    else:
        target_col = df.columns[-1]
        y = df[df.columns[-1]]
        X = df.iloc[:, :-1]

    numeric_features = X.select_dtypes(include="number").columns.tolist()
    categorical_features = [c for c in X.columns if c not in numeric_features]

    results = train_and_evaluate_model(
        X, y, numeric_features, categorical_features,
        test_size=test_size, random_state=42,
    )

    report = {
        "status": "ok",
        "tool": "classify",
        "target": str(target_col),
        "n_samples": int(X.shape[0]),
        "n_features": int(X.shape[1]),
        "numeric_features": numeric_features,
        "categorical_features": categorical_features,
        "classes": sorted(str(c) for c in np.unique(y)),
        "metrics": {k: float(v) for k, v in results["metrics"].items()},
    }
    with open(out, "w") as f:
        json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
