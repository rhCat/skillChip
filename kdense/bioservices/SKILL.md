---
skill: bioservices
name: BioServices (bioinformatics web APIs)
perks: [batch_id_convert, compound_xref, pathway_network, protein_workflow]
---

# bioservices — BioServices (bioinformatics web APIs)

Query 40+ bioinformatics web services (UniProt, KEGG, ChEMBL, Reactome) through one governed
interface — ID mapping, compound cross-reference, pathway networks, and protein workflows.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

Every perk is read-only: it queries remote bioinformatics APIs and writes local files only — no
remote service is mutated. The cores need the `bioservices` Python package (PyPI) and internet
access to the EBI/NCBI/KEGG/UniProt web APIs; `protein_workflow` BLAST also needs `NCBI_EMAIL`.
When the package or network is absent the porter degrades gracefully (the named output is still
created), so a governed run never aborts mid-sequence.

## Perks
| perk | tool | nature |
|---|---|---|
| `batch_id_convert` | `batch_id_convert` | read-only — UniProt batch ID mapping → `mapping_results.csv` |
| `compound_xref` | `compound_xref` | read-only — KEGG/ChEBI/ChEMBL cross-reference → `compound_xref.txt` |
| `pathway_network` | `pathway_network` | read-only — KEGG pathway summary + SIF network → `pathway_summary.csv` |
| `protein_workflow` | `protein_workflow` | read-only — UniProt/BLAST/KEGG/PSICQUIC/GO → `protein_report.txt` |

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `bioservices` — MIT (see LICENSE.txt).
