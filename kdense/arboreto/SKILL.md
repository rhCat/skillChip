---
skill: arboreto
name: Arboreto (GRN inference)
perks: [grnboost2, genie3]
---

# arboreto — Arboreto (GRN inference)

Infer gene regulatory networks (GRNs) from gene expression data using scalable
tree-based ensemble regression (GRNBoost2, GENIE3). Each perk reads an expression
matrix (TSV, genes as columns, observations as rows) and writes a TF–target–importance
network. Read-only and local: it produces files under `record_store` and never mutates
remote state.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named network TSV + the
executor run-ledger. The heavy science stack (`arboreto`, `dask`, `distributed`,
`scikit-learn`) is invoked through a vendored Python core; when it is absent the porter
degrades gracefully (empty network) so the contract still holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `grnboost2` | `grnboost2` | read-only / safe — gradient-boosting GRN inference → `network.tsv` |
| `genie3` | `genie3` | read-only / safe — Random-Forest GRN inference → `network.tsv` |

Both perks share the same I/O contract: an `EXPRESSION_FILE` (TSV, genes as columns),
an optional `TF_FILE` (one TF name per line; empty = all genes are potential regulators),
an optional reproducibility `SEED`, and an optional `LIMIT` (top-N regulatory links). They
differ only in the underlying regressor — `grnboost2` uses stochastic gradient boosting
(fast, recommended for large single-cell data), `genie3` uses Random Forest (the classic
multiple-regression approach, useful for comparison/validation). Neither touches remote
services, so both are declared `destructive: false`.

## How to use it
Pick a perk (`grnboost2` or `genie3`), copy `ledger.json` → `task-ledger.json`, fill its vars +
`record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `arboreto` — MIT (see LICENSE.txt).
