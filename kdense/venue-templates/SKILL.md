---
skill: venue-templates
name: Venue Templates
perks: [query, customize, validate, schematic]
---

# venue-templates — Venue Templates

Query, customize, and validate scientific publication venue templates (Nature, Science, PLOS, IEEE, ACM, NeurIPS, ICML, CHI), research posters, and grant proposals (NSF, NIH, DOE, DARPA).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `query` | `query_template` | read-only — search/list templates + print venue formatting requirements |
| `customize` | `customize_template` | local file gen — fill a `.tex` template's title/author/affiliation/email placeholders |
| `validate` | `validate_format` | read-only — check a manuscript PDF's page count, margins, fonts vs venue rules (`pdfinfo`/`pdffonts`) |
| `schematic` | `generate_schematic` | network — generate a publication-quality diagram via the OpenRouter image API (needs `OPENROUTER_API_KEY`) |

The `query`, `customize`, and `validate` perks are pure-stdlib Python and run fully offline (each
degrades gracefully when an optional helper like `pdfinfo` is absent). The `schematic` perk calls a
remote LLM image service and therefore requires `OPENROUTER_API_KEY` and network access.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `venue-templates` — MIT (see LICENSE.txt).
