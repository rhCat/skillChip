#!/usr/bin/env python3
"""visualize_cli — thin CLI driver around the vendored clustering_analysis.py core.

Reads a CSV (all columns = features), standard-scales it, labels it with K-Means at
n_clusters=N_CLUSTERS, then calls the vendored visualize_clusters to project to 2D with
PCA and render a labeled cluster scatter. Writes a small JSON manifest of what was drawn.

env in:  DATA_CSV (required), N_CLUSTERS (optional int, default 3),
         PLOT (optional path for clustering_results.png), OUT (required output path)
out:     JSON {status, n_clusters, plot, cluster_sizes}

The heavy dependency is scikit-learn; if it is missing this driver exits non-zero and
the porter degrades to a graceful {} -> note line.
"""
import json
import os
import sys


def main():
    out = os.environ["OUT"]
    data_csv = os.environ["DATA_CSV"]
    n_clusters = int(os.environ.get("N_CLUSTERS", "3"))
    plot = os.environ.get("PLOT", "").strip()

    import matplotlib
    matplotlib.use("Agg")  # headless; render PNG without a display
    import numpy as np
    import pandas as pd
    from sklearn.cluster import KMeans
    from sklearn.preprocessing import StandardScaler

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from clustering_analysis import visualize_clusters

    df = pd.read_csv(data_csv)
    X = df.select_dtypes(include="number").to_numpy()
    X = StandardScaler().fit_transform(X)

    labels = KMeans(n_clusters=n_clusters, random_state=42, n_init=10).fit_predict(X)
    results = {"K-Means": {"labels": labels, "n_clusters": n_clusters}}

    # The vendored core writes clustering_results.png in the CWD; the porter cd's into
    # RECORD_STORE so the plot lands there. Honor PLOT by relocating if needed.
    visualize_clusters(X, results)

    if plot and os.path.exists("clustering_results.png") and \
            os.path.abspath("clustering_results.png") != os.path.abspath(plot):
        os.replace("clustering_results.png", plot)

    unique, counts = np.unique(labels, return_counts=True)
    report = {
        "status": "ok",
        "tool": "visualize",
        "n_samples": int(X.shape[0]),
        "n_clusters": int(n_clusters),
        "cluster_sizes": {int(u): int(c) for u, c in zip(unique, counts)},
    }
    with open(out, "w") as f:
        json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
