---
skill: security-ownership-map
name: Security Ownership Map
perks: [build, query, community_maintainers]
---

# security-ownership-map — Security Ownership Map

Build a people-to-file security ownership topology from git history, query bounded slices of it, and report community maintainers over time. All perks are read-only.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The Python cores are vendored under each perk's `src/`. Community detection and GraphML need `networkx`; when it is absent the `build` perk degrades to co-change + summary only and still produces `summary.json`.

## Perks
| perk | tool | nature |
|---|---|---|
| `build` | `build_map` | read-only / safe — reads `git log`, writes CSV/JSON ownership artifacts to `record_store` |
| `query` | `query_map` | read-only / safe — bounded JSON slices over a built ownership-map dir |
| `community_maintainers` | `community_maintainers` | read-only / safe — monthly/quarterly maintainers for a file's community |

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

- `build`: set `REPO` (the git repo dir). Output: `summary.json` (plus `people.csv`, `files.csv`, `edges.csv`, `cochange_edges.csv`, and `communities.json` / `cochange.graph.json` when `networkx` is present) under `record_store`.
- `query`: set `DATA_DIR` (a built ownership-map dir) and `QUERY_ARGS` (e.g. `files --tag auth --bus-factor-max 1`). Output: `query.json`.
- `community_maintainers`: set `DATA_DIR` and `CM_ARGS` (e.g. `--file network/card.c --since 2025-01-01 --top 5`). Output: `community_maintainers.csv`.

> Localized from [openai/skills](https://github.com/openai/skills) `security-ownership-map` — Apache-2.0 (see LICENSE.txt).
