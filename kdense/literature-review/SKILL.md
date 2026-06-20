---
skill: literature-review
name: Literature Review
perks: [aggregate, verify-citations, generate-pdf, generate-schematic]
---

# literature-review — Literature Review

Aggregate search results, verify citations, render PDFs, and generate schematics for systematic literature reviews.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/output + the executor run-ledger.

These perks port the deterministic cores of the K-Dense literature-review skill — they do not perform the
database searches themselves. Feed them JSON exported from your searches (`aggregate`), a finished review
markdown (`verify-citations`, `generate-pdf`), or a diagram prompt (`generate-schematic`).

## Perks
| perk | tool | nature |
|---|---|---|
| `aggregate` | `search_databases` | read-only / safe — stdlib dedup + rank + year-filter + format (json/markdown/bibtex) |
| `verify-citations` | `verify_citations` | read-only — extract DOIs, resolve via doi.org + CrossRef, emit report (network) |
| `generate-pdf` | `generate_pdf` | read-only — markdown → PDF via pandoc/xelatex |
| `generate-schematic` | `generate_schematic` | read-only / file-producing — AI schematic from a prompt (needs OPENROUTER_API_KEY + network) |

`aggregate` is fully hermetic (Python stdlib only). `verify-citations` reaches doi.org + the CrossRef API;
`generate-pdf` shells out to `pandoc`/`xelatex`; `generate-schematic` calls the OpenRouter API (Nano Banana /
Gemini) and needs `OPENROUTER_API_KEY`. Every porter degrades gracefully when its heavy dependency is absent,
always (re)creating its output file so the contract holds. None of the perks mutate remote/live state, so all
are declared `destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `literature-review` — MIT (see LICENSE.txt).
