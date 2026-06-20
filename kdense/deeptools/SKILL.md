---
skill: deeptools
name: deepTools (NGS analysis)
perks: [validate, gen_chipseq_qc, gen_chipseq_analysis, gen_rnaseq_coverage, gen_atacseq]
---

# deeptools — deepTools (NGS analysis)

Validate NGS input files (BAM/bigWig/BED) and generate deepTools workflow scripts (read-only).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `validate` | `validate_files` | read-only — checks file existence, BAM index, BED format → `validation.txt` |
| `gen_chipseq_qc` | `gen_chipseq_qc` | read-only — emits a ChIP-seq QC bash workflow → `chipseq_qc.sh` |
| `gen_chipseq_analysis` | `gen_chipseq_analysis` | read-only — emits a full ChIP-seq analysis bash workflow → `chipseq_analysis.sh` |
| `gen_rnaseq_coverage` | `gen_rnaseq_coverage` | read-only — emits a strand-specific RNA-seq coverage bash workflow → `rnaseq_coverage.sh` |
| `gen_atacseq` | `gen_atacseq` | read-only — emits an ATAC-seq bash workflow (Tn5 shift) → `atacseq.sh` |

All perks are read-only: `validate` inspects files without modifying them; the `gen_*` perks write a
customizable bash script (deepTools commands) into `record_store` but never run those commands or touch
any sequencing data. The generated scripts are templates for the user to review and execute separately.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `deeptools` — MIT (see LICENSE.txt).
