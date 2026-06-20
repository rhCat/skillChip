---
skill: market-research-reports
name: Market Research Reports
perks: [visuals]
---

# market-research-reports — Market Research Reports

Batch-generate the standard visual set for a 50+ page consulting-style market research report
(growth trajectory, TAM/SAM/SOM, Porter's Five Forces, competitive positioning, risk heatmap,
plus an extended set) from a single market topic.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts
under `record_store`. LOGS TO CHECK: that line + the named manifest + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `visuals` | `market_visuals` | read-only / local — plans + (when the image backends are present) generates the report visual set, writing a manifest under `record_store` |

The `visuals` perk drives the vendored `generate_market_visuals.py`, which fans out to the
`scientific-schematics` and `generate-image` skill scripts to render each figure. The actual
rendering needs those image backends; when they are absent the porter degrades gracefully and
still writes a deterministic manifest of every visual it would produce, so the contract holds
offline. It never mutates a remote or live service, so it is declared `destructive: false`.

## How to use it
Pick the `visuals` perk, copy `ledger.json` → `task-ledger.json`, fill `TOPIC` (and optionally
`ALL=1` for the extended set) plus `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `market-research-reports` — MIT (see LICENSE.txt).
