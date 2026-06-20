---
skill: phylogenetics
name: Phylogenetics
perks: [align, infer_iqtree, infer_fasttree, tree_summary, visualize]
---

# phylogenetics — Phylogenetics

Align sequences, infer phylogenetic trees (IQ-TREE / FastTree), and summarize or visualize them.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `align` | `mafft_align` | read-only / file-producing — MAFFT multiple sequence alignment (FASTA → aligned FASTA) |
| `infer_iqtree` | `iqtree_infer` | read-only / file-producing — IQ-TREE 2 maximum-likelihood tree with model selection + ultrafast bootstrap |
| `infer_fasttree` | `fasttree_infer` | read-only / file-producing — FastTree fast approximate ML tree (large datasets) |
| `tree_summary` | `tree_summary` | read-only — ETE3 tree statistics (taxa count, branch lengths) → JSON |
| `visualize` | `tree_visualize` | read-only / file-producing — ETE3 rooted-tree render (PNG, with Newick fallback) |

Each perk wraps one independent operation from the vendored `phylogenetic_analysis.py` core. `align`
produces an aligned FASTA; `infer_iqtree` / `infer_fasttree` consume an alignment and emit a Newick
tree; `tree_summary` and `visualize` consume a Newick tree. All perks are `destructive: false` — they
read inputs and write local artifacts only, never mutating a remote or live service.

## How to use it
Pick a perk (`align`, `infer_iqtree`, `infer_fasttree`, `tree_summary`, `visualize`), copy `ledger.json`
→ `task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight →
executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `phylogenetics` — MIT (see LICENSE.txt).
