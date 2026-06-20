#!/usr/bin/env python3
"""cluster_compare_cli — thin CLI driver around the vendored clustering_analysis.py core.

Reads a CSV (all columns = features), standard-scales it, then calls the vendored
compare_clustering_algorithms to run K-Means, Agglomerative, Gaussian Mixture, and
DBSCAN at n_clusters=N_CLUSTERS, scoring each with silhouette, Calinski-Harabasz, and
Davies-Bouldin. Writes the per-algorithm scores as JSON.

env in:  DATA_CSV (required), N_CLUSTERS (optional int, default 3), OUT (required output path)
out:     JSON {status, n_clusters, algorithms:{name:{silhouette,calinski_harabasz,davies_bouldin,...}}}

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

    import pandas as pd
    from sklearn.preprocessing import StandardScaler

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from clustering_analysis import compare_clustering_algorithms

    df = pd.read_csv(data_csv)
    X = df.select_dtypes(include="number").to_numpy()
    X = StandardScaler().fit_transform(X)

    results = compare_clustering_algorithms(X, n_clusters=n_clusters)

    # Strip non-JSON-serializable label arrays; keep the scalar metrics.
    algorithms = {}
    for name, r in results.items():
        algorithms[name] = {
            k: (float(v) if isinstance(v, float) else int(v))
            for k, v in r.items() if k != "labels"
        }

    report = {
        "status": "ok",
        "tool": "cluster_compare",
        "n_samples": int(X.shape[0]),
        "n_clusters": int(n_clusters),
        "algorithms": algorithms,
    }
    with open(out, "w") as f:
        json.dump(report, f, indent=2)


if __name__ == "__main__":
    main()
