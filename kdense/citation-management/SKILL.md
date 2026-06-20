---
skill: citation-management
name: Citation Management
perks: [search_pubmed, search_scholar, extract_metadata, doi_to_bibtex, format_bibtex, validate_citations, generate_schematic]
---

# citation-management — Citation Management

Search PubMed/Scholar, extract paper metadata, convert DOIs, and format/validate BibTeX bibliographies.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named output file + the executor run-ledger.
The search/extract/doi/schematic perks reach external services (NCBI, Google Scholar, CrossRef, arXiv,
OpenRouter); the porter degrades gracefully (writes `{}` and exits 0) when a service or library is absent.
The `format_bibtex` and `validate_citations` perks run fully offline.

## Perks
| perk | tool | nature |
|---|---|---|
| `search_pubmed` | `search_pubmed` | read-only — NCBI E-utilities search → `pubmed.json` |
| `search_scholar` | `search_scholar` | read-only — Google Scholar (scholarly lib) → `scholar.json` |
| `extract_metadata` | `extract_metadata` | read-only — DOI/PMID/arXiv/URL → `metadata.bib` |
| `doi_to_bibtex` | `doi_to_bibtex` | read-only — CrossRef DOI → `references.bib` |
| `format_bibtex` | `format_bibtex` | read-only / offline — clean+dedupe+sort → `formatted.bib` |
| `validate_citations` | `validate_citations` | read-only / offline — checks → `validation.json` |
| `generate_schematic` | `generate_schematic` | read-only — LLM image gen (needs `OPENROUTER_API_KEY`) → `schematic.png` |

All perks are read-only (`destructive: false`): they produce files under `record_store` and never mutate a
remote/live service. `format_bibtex` and `validate_citations` need no network; the rest call external
APIs but never write to them.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `citation-management` — MIT (see LICENSE.txt).
