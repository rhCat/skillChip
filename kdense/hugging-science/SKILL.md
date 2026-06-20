---
skill: hugging-science
name: Hugging Science (catalog discovery)
perks: [topics, topic, all, search, raw]
---

# hugging-science — Hugging Science (catalog discovery)

Discover scientific ML datasets, models, blog posts, and interactive Spaces from the curated
Hugging Science catalog (`huggingscience.co`). All perks are read-only: they fetch and parse the
catalog's LLM-friendly markdown (`llms.txt`, `llms-full.txt`, `topics/<slug>.md`) into clean
markdown or structured JSON. Resources are pointers to the broader Hugging Face Hub — you USE them
via standard `datasets` / `transformers` / `gradio_client`; this cartridge only does discovery.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. The catalog lives on the network: when offline (or the host 404s), the porter still
produces a non-empty output file recording the failure, so the contract holds. LOGS TO CHECK: that
JSON line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `topics` | `hs_topics` | read-only / offline — lists the 17 known topic slugs (no network) |
| `topic` | `hs_topic` | read-only — fetch + parse one `topics/<slug>.md` (filter by section/tag) |
| `all` | `hs_all` | read-only — fetch + parse the full `llms-full.txt` (every domain) |
| `search` | `hs_search` | read-only — substring search across the full catalog |
| `raw` | `hs_raw` | read-only — dump a raw index file (`llms.txt` / `llms-full.txt`) untouched |

`topics` needs no network — it prints the hard-coded slug list. The other four fetch from
`huggingscience.co` over HTTPS; they are still read-only (GET only, no mutation anywhere).

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `hugging-science` — MIT (see LICENSE.txt).
