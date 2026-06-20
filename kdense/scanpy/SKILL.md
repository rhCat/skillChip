---
skill: scanpy
name: Scanpy (single-cell RNA-seq)
perks: [inspect, convert, qc, preprocess, reduce_dimensions, batch_correct, cluster, find_markers, annotate, score_genes, pseudobulk, subset, plot, run_pipeline]
---

# scanpy — Scanpy (single-cell RNA-seq)

Governed single-cell RNA-seq workflow built on the K-Dense scanpy script toolkit:
inspect, convert, QC, normalize, reduce dimensions, integrate batches, cluster,
find markers, annotate cell types, score gene sets, pseudobulk, subset, and plot.
Each operation is one independent `.h5ad`-in / artifact-out perk; the perks chain.

## Purpose
Run established scanpy operations deterministically and under audit. Every perk
wraps one vendored CLI core (`scripts/*.py`, sharing `_common.py`), translates
governed env vars into CLI flags, writes its artifacts under `record_store`, and
emits one structured-JSON audit line. The heavy science library (`scanpy`) is the
actual engine; the porter degrades gracefully (still produces its output file and
exits 0) when scanpy is not installed, so governance/contract checks hold offline.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the
executor run-ledger. Perks that need scanpy installed produce real `.h5ad`/CSV
artifacts only when the library is present; otherwise a placeholder output file is
written so the contract still passes.

## Perks
| perk | tool | nature |
|---|---|---|
| `inspect` | `inspect_data` | read-only / summarize shape, obs/var, layers, embeddings |
| `convert` | `convert` | load any format -> `.h5ad` |
| `qc` | `qc_analysis` | QC metrics + filter cells/genes + plots, optional Scrublet |
| `preprocess` | `preprocess` | normalize + log1p + HVG, optional scale/regress |
| `reduce_dimensions` | `reduce_dimensions` | PCA + neighbors + UMAP, optional t-SNE |
| `batch_correct` | `batch_correct` | integration: harmony / bbknn / combat |
| `cluster` | `cluster` | Leiden/louvain at one or many resolutions |
| `find_markers` | `find_markers` | `rank_genes_groups` + per-group CSVs + plots |
| `annotate` | `annotate` | map clusters -> cell types from JSON/CSV mapping |
| `score_genes` | `score_genes` | score gene signatures and/or cell-cycle phase |
| `pseudobulk` | `pseudobulk` | aggregate by sample x cell type -> matrix for pydeseq2 |
| `subset` | `subset` | subset by obs values or gene list |
| `plot` | `plot` | render umap/tsne/pca/violin/dotplot/heatmap/etc. |
| `run_pipeline` | `run_pipeline` | full workflow in one command (counts -> clustered + markers) |

All perks are read-only / file-producing (`destructive: false`): they read input
files and write new artifacts under `record_store`; none mutate a remote/live
service. Output is a new `.h5ad` (or CSV/figures) — inputs are never overwritten.

## How to use it
Pick a perk, copy `ledger.json` -> `task-ledger.json`, fill its vars + `record_store`,
then validate -> compose -> compile -> oversight -> executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scanpy` — MIT (see LICENSE.txt).
