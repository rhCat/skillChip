#!/usr/bin/env python3
"""optimal_k_cli — thin CLI driver around the vendored clustering_analysis.py core.

Reads a CSV (all columns = features), standard-scales it, then calls the vendored
find_optimal_k_kmeans to sweep K over [K_MIN, K_MAX], recording inertia (elbow) +
silhouette per K, saving the elbow/silhouette plot, and reporting the recommended K.

env in:  DATA_CSV (required), K_MIN (optional int, default 2), K_MAX (optional int, default 8),
         PLOT (optional path for clustering_optimization.png), OUT (required output path)
out:     JSON {status, k_values, inertias, silhouette_scores, best_k}

The heavy dependency is scikit-learn; if it is missing this driver exits non-zero and
the porter degrades to a graceful {} -> note line.
"""
import json
import os
import sys


def main():
    out = os.environ["OUT"]
    data_csv = os.environ["DATA_CSV"]
    k_min = int(os.environ.get("K_MIN", "2"))
    k_max = int(os.environ.get("K_MAX", "8"))
    plot = os.environ.get("PLOT", "").strip()

    import matplotlib
    matplotlib.use("Agg")  # headless; render PNG without a display
    import pandas as pd
    from sklearn.preprocessing import StandardScaler

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from clustering_analysis import find_optimal_k_kmeans

    df = pd.read_csv(data_csv)
    X = df.select_dtypes(include="number").to_numpy()
    X = StandardScaler().fit_transform(X)

    n = X.shape[0]
    # silhouette needs at least k+1 samples and 2<=k<n
    k_max = min(k_max, max(2, n - 1))

    # The vendored core writes clustering_optimization.png in the CWD; the porter cd's
    # into RECORD_STORE so the plot lands there. Honor PLOT by relocating if needed.
    res = find_optimal_k_kmeans(X, k_range=range(k_min, k_max + 1))

    if plot and os.path.exists("clustering_optimization.png") and \
            os.path.abspath("clustering_optimization.png") != os.path.abspath(plot):
        os.replace("clustering_optimization.png", plot)

    report = {
        "status": "ok",
        "tool": "optimal_k",
        "n_samples": int(n),
        "k_values": [int(k) for k in res["k_values"]],
        "inertias": [float(v) for v in res["inertias"]],
        "silhouette_scores": [float(v) for v in res["silhouette_scores"]],
        "best_k": int(res["best_k"]),
    }
    with open(out, "w") as f:
        json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
