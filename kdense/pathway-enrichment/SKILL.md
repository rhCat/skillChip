---
skill: pathway-enrichment
name: Pathway Enrichment
perks: [ora, gsea]
---

# pathway-enrichment — Pathway Enrichment

Run pathway / gene-set enrichment on a gene list or ranked gene data, then read the tables out: over-representation (ORA / Enrichr / Fisher) on a thresholded hit list, or preranked GSEA on a full ranked list (e.g. a DESeq2 `stat` column).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
Both perks call `gseapy`, which needs network access for Enrichr / library downloads; with the library
absent or offline the porter still produces a valid (degraded) report so the contract holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `ora` | `run_ora` | read-only — Enrichr over-representation of a gene hit list against gene-set libraries |
| `gsea` | `run_gsea` | read-only — preranked GSEA from a DESeq2 results table or an explicit `gene,score` rank file |

The `ora` perk cleans/dedupes gene symbols, runs `gp.enrichr`, and writes the full + significant tables
(`ora_results.csv`, `ora_significant.csv`) plus a dotplot. The `gsea` perk builds the ranking metric
(prefers the Wald `stat`, else `sign(log2FC) * -log10(p)`), runs `gp.prerank` with a fixed seed, and writes
`gsea_results.csv`, `gsea_significant.csv`, and a dotplot. Both are read-only / local file producers
(`destructive: false`).

## How to use it
Pick a perk (`ora` or `gsea`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pathway-enrichment` — MIT (see LICENSE.txt).
