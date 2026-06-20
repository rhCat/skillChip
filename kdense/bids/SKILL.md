---
skill: bids
name: Brain Imaging Data Structure (BIDS)
perks: [update_schema, update_beps]
---

# bids — Brain Imaging Data Structure (BIDS)

Refresh the machine-readable BIDS schema and the BIDS Extension Proposals (BEPs) listing from upstream sources. Both perks are read-only network fetches that re-serialize the downloaded artifact under `record_store`.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifact under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
Both perks require network access to reach the upstream sources; the porter degrades gracefully
(writes an empty `{}` artifact and exits 0) when the fetch fails, so the contract still holds offline.

## Perks
| perk | tool | nature |
|---|---|---|
| `update_schema` | `update_schema` | read-only — fetch `schema.json` from `SCHEMA_URL`, write `bids_schema.json` |
| `update_beps` | `update_beps` | read-only — fetch `beps.yml` from bids-website, write `beps.yml` |

The `update_schema` perk downloads the BIDS schema JSON (default the stable ReadTheDocs export, or any
`SCHEMA_URL` such as a version pin or a BEP-specific preview), validates it as JSON, and re-serializes it
with consistent indentation. The `update_beps` perk downloads the canonical BEPs listing. Neither perk
mutates a remote service, so both are declared `destructive: false`.

## How to use it
Pick a perk (`update_schema` or `update_beps`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `bids` — MIT (see LICENSE.txt).
