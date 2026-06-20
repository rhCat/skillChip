---
skill: scikit-learn
name: Scikit-learn (classical ML)
perks: [classify, optimal_k, cluster_compare, visualize]
---

# scikit-learn — Scikit-learn (classical ML)

Classical machine learning with scikit-learn: classify a labeled table, cluster an unlabeled one, find the optimal number of clusters, and project clusters to 2D. Every perk is read-only with respect to its inputs and writes its artifacts under `record_store`.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report (JSON or PNG) + the executor run-ledger.
The heavy science library is `scikit-learn`; when it is absent the porter degrades gracefully (it still
writes a non-empty JSON report noting the missing dependency) so the governed run stays green offline.

## Perks
| perk | tool | nature | output |
|---|---|---|---|
| `classify` | `classify` | read-only / safe | `classification.json` |
| `optimal_k` | `optimal_k` | read-only / safe | `optimal_k.json` (+ `clustering_optimization.png`) |
| `cluster_compare` | `cluster_compare` | read-only / safe | `cluster_compare.json` |
| `visualize` | `visualize` | read-only / safe | `cluster_visualization.json` (+ `clustering_results.png`) |

- `classify` preprocesses a CSV (median-impute + standard-scale numeric, most-frequent-impute + one-hot categorical), compares Logistic Regression / Random Forest / Gradient Boosting by 5-fold CV, tunes the winner with `GridSearchCV`, then reports accuracy / precision / recall / F1 (and ROC AUC when binary) plus top feature importances.
- `optimal_k` sweeps K over a range, records inertia (elbow) and silhouette per K, saves the elbow/silhouette plot, and reports the silhouette-recommended K.
- `cluster_compare` standardizes the data and scores K-Means, Agglomerative, Gaussian Mixture, and DBSCAN with silhouette, Calinski-Harabasz, and Davies-Bouldin.
- `visualize` reduces the scaled data to 2D with PCA, labels it with K-Means, and renders a labeled cluster scatter.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars (`DATA_CSV`, plus the perk's optional knobs) + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scikit-learn` — MIT (see LICENSE.txt).
