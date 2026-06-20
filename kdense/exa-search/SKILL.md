---
skill: exa-search
name: Exa Web Toolkit
perks: [search, extract]
---

# exa-search — Exa Web Toolkit

Search the web or extract URL content via the Exa API (read-only). Exa's index combines
keyword and semantic retrieval, with optional `research paper` category + academic domain
filtering for scholarly work.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `search` | `exa_search` | read-only / network (`client.search_and_contents`) → `search.json` |
| `extract` | `exa_extract` | read-only / network (`client.get_contents`) → `extract.json` |

Both perks are read-only: they query the Exa API and write a JSON report; nothing on the
remote service is mutated. They need the `exa-py` SDK, an `EXA_API_KEY`, and internet access;
when any of those is absent the porter degrades gracefully to an empty `{}` report.

## How to use it
Pick a perk (`search` or `extract`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `exa-search` — MIT (see LICENSE.txt).
