---
skill: research-lookup
name: Research Information Lookup
perks: [research-lookup, generate-schematic]
---

# research-lookup — Research Information Lookup

Route a research query to the best backend (Parallel Chat API for general research, Perplexity
sonar-pro-search for academic paper searches) and save a cited report, or render a
publication-quality scientific schematic from a natural-language description.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report/image + the executor run-ledger. Query
text and prompts are transmitted to external services (`api.parallel.ai` via `PARALLEL_API_KEY`,
`openrouter.ai` via `OPENROUTER_API_KEY`). With no key / no network the porter degrades gracefully:
it still writes a (placeholder) output file so the contract holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `research-lookup` | `research_lookup` | read-only / network — routed query, writes cited report (`.md`/`.json`) |
| `generate-schematic` | `generate_schematic` | read-only / network — writes a generated diagram image |

The `research-lookup` perk auto-routes by query content: academic keywords (papers, DOI, pubmed,
peer-reviewed, etc.) go to Perplexity; everything else goes to the Parallel Chat API. The backend can
be forced with `FORCE_BACKEND`. The `generate-schematic` perk wraps the AI schematic generator,
producing an image under `record_store`. Neither mutates a remote service, so both are
`destructive: false`.

## How to use it
Pick a perk (`research-lookup` or `generate-schematic`), copy `ledger.json` → `task-ledger.json`, fill
its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `research-lookup` — MIT (see LICENSE.txt).
