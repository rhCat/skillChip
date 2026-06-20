---
skill: primekg
name: PrimeKG (Precision Medicine Knowledge Graph)
perks: [search_nodes, get_neighbors, find_paths, get_disease_context]
---

# primekg — PrimeKG (Precision Medicine Knowledge Graph)

Query PrimeKG — a precision-medicine knowledge graph of ~129k nodes and ~4M edges across
genes/proteins, drugs, diseases and phenotypes — for nodes, direct neighbors, drug-disease
paths, and disease context. All perks are read-only analyses over a local PrimeKG `kg.csv`.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
The KG edge-list CSV is supplied via `PRIMEKG_CSV` (columns: `relation, display_relation,
x_id, x_type, x_name, x_source, y_id, y_type, y_name, y_source`).

## Perks
| perk | tool | nature |
|---|---|---|
| `search_nodes` | `search_nodes` | read-only — substring node search by name (+ optional type) |
| `get_neighbors` | `get_neighbors` | read-only — direct neighbors of a node (+ optional relation filter) |
| `find_paths` | `find_paths` | read-only — direct (depth-1) paths between two nodes |
| `get_disease_context` | `get_disease_context` | read-only — genes/drugs/phenotypes around a disease |

Every perk loads the local `kg.csv` with pandas and writes a JSON report to `record_store`;
none mutates the graph or any remote service, so all are declared `destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars (point `PRIMEKG_CSV` at a
PrimeKG `kg.csv`) + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `primekg` — MIT (see LICENSE.txt).
