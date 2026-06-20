---
skill: pydeseq2
name: PyDESeq2 (Differential Expression)
perks: [filter, dea, plots]
---

# pydeseq2 — PyDESeq2 (Differential Expression)

Filter RNA-seq counts, run PyDESeq2 differential expression, and render volcano/MA plots.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `filter` | `filter_counts` | read-only / safe — drop low-count genes + missing-metadata samples (pure pandas) |
| `dea` | `run_dea` | read-only / file-producing — full DESeq2 fit + Wald test + LFC shrink + CSV/H5AD export (needs `pydeseq2`) |
| `plots` | `render_plots` | read-only / file-producing — volcano + MA plots from a results CSV (matplotlib) |

The `filter` perk loads a counts matrix (genes × samples; transposed to samples × genes), removes
genes below `MIN_COUNTS` total reads and samples with missing condition data, and writes
`filtered_counts.csv`. The `dea` perk runs the complete PyDESeq2 pipeline — size factors, dispersion
fitting, Wald tests with Benjamini-Hochberg FDR correction, optional apeGLM LFC shrinkage — and exports
`deseq2_results.csv`. The `plots` perk reads a DESeq2 results CSV and renders `volcano_plot.png` and
`ma_plot.png`. All three are non-destructive and write only under `record_store`.

## How to use it
Pick a perk (`filter`, `dea`, or `plots`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pydeseq2` — MIT (see LICENSE.txt).
