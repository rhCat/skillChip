---
skill: scvelo
name: scVelo (RNA Velocity)
perks: [load, preprocess, velocity, latent_time, velocity_pseudotime, driver_genes, plot_embedding, run_workflow]
---

# scvelo — scVelo (RNA Velocity)

Estimate RNA velocity from spliced/unspliced single-cell counts: preprocess, fit velocity, latent time, driver genes, and embedding plots.

scVelo infers cell-state transitions by modeling mRNA splicing kinetics — the ratio of unspliced (pre-mRNA) to spliced (mature mRNA) abundance per gene per cell. Each perk is one independent, deterministic step of the standard velocity workflow, reading and writing AnnData `.h5ad` so steps compose.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/`.h5ad`/figure + the executor run-ledger.
Inputs must be AnnData with `layers["spliced"]` and `layers["unspliced"]` (produced upstream by velocyto / STARsolo / kallisto|bustools); the `load` perk ingests velocyto `.loom`.

## Perks
| perk | tool | nature |
|---|---|---|
| `load` | `load` | read-only — `.loom` (+ optional processed `.h5ad`) -> merged `.h5ad` |
| `preprocess` | `preprocess` | read-only — `filter_and_normalize` + `neighbors` + `moments` -> `.h5ad` |
| `velocity` | `velocity` | read-only — `recover_dynamics` (dynamical) + `velocity` + `velocity_graph` -> `.h5ad` |
| `latent_time` | `latent_time` | read-only — shared latent time (dynamical) -> `.h5ad` |
| `velocity_pseudotime` | `velocity_pseudotime` | read-only — `velocity_pseudotime` + `velocity_confidence` -> `.h5ad` |
| `driver_genes` | `driver_genes` | read-only — `rank_velocity_genes` per group -> CSV |
| `plot_embedding` | `plot_embedding` | read-only — velocity embedding stream/grid/arrows -> PNG |
| `run_workflow` | `run_workflow` | read-only — full pipeline in one command -> `.h5ad` + figures |

Every perk is read-only / local analysis: it reads an input `.h5ad`/`.loom` and writes new artifacts under `record_store`, never mutating the input. All are declared `destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scvelo` — MIT (see LICENSE.txt).
