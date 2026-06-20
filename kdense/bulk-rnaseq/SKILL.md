---
skill: bulk-rnaseq
name: Bulk RNA-seq
perks: [validate_samplesheet, counts_from_salmon, counts_from_star, counts_from_featurecounts]
---

# bulk-rnaseq — Bulk RNA-seq

Validate a bulk RNA-seq samplesheet and bridge Salmon/STAR/featureCounts quant output into a PyDESeq2-ready gene-level counts matrix.

## What this cartridge governs

The end-to-end bulk RNA-seq study (FASTQ → QC/trim → align/quant → counts → DE → enrichment → figures) is mostly a router across other tools. This cartridge governs the two **deterministic, file-in/file-out** operations the skill actually owns: pre-flight samplesheet/design validation, and the counts → DE bridge that turns quantifier output into the exact `counts.csv` PyDESeq2 expects.

Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. LOGS TO CHECK: that line + the named report/matrix + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `validate_samplesheet` | `validate_samplesheet` | read-only — checks samplesheet (+ metadata) for FASTQ/strandedness/replication/confounding issues |
| `counts_from_salmon` | `counts_from_salmon` | local analysis — Salmon `quant.sf` → gene-level integer counts via pytximport (`length_scaled_tpm`) |
| `counts_from_star` | `counts_from_star` | local analysis — STAR `*.ReadsPerGene.out.tab` → gene × sample matrix (strandedness column) |
| `counts_from_featurecounts` | `counts_from_featurecounts` | local analysis — combined featureCounts matrix → gene × sample matrix |

`validate_samplesheet` only reads inputs and writes a report. The three `counts_*` perks each take one quantifier's output and write `counts.csv` (genes × samples, integers — never TPM/FPKM) plus a `metadata_template.csv` to fill in before handing off to the `pydeseq2` skill. All four are `destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `bulk-rnaseq` — MIT (see LICENSE.txt).
