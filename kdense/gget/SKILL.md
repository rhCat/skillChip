---
skill: gget
name: gget (bioinformatics queries)
perks: [gene_analysis, sequence_analysis, enrichment]
---

# gget — gget (bioinformatics queries)

Query 20+ genomic databases via gget: gene analysis, batch sequence BLAST/alignment, and enrichment (read-only).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
Every perk wraps the `gget` Python package, which queries live remote databases — runs need network and an
installed `gget` (`uv pip install "gget==0.30.5"`). With `gget` absent the porter degrades gracefully:
it pre-creates the output, captures the import error, and still writes a non-empty report so the contract holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `gene_analysis` | `gene_analysis` | read-only — search/info/seq/archs4/opentargets for one gene, writes CSV + FASTA |
| `sequence_analysis` | `sequence_analysis` | read-only — BLAST each FASTA record + MUSCLE alignment, writes CSV + .afa |
| `enrichment` | `enrichment` | read-only — Enrichr enrichment over a gene list across 5 databases, writes CSV |

All three perks only read from remote databases and write local files, so each is declared `destructive: false`.
They never mutate a remote service or install anything (`gget setup` / `gget alphafold` are out of scope here).

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `gget` — MIT (see LICENSE.txt).
