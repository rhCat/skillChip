---
skill: scholar-evaluation
name: Scholar Evaluation (ScholarEval)
perks: [score, schematic]
---

# scholar-evaluation — Scholar Evaluation (ScholarEval)

Compute weighted ScholarEval dimension scores into a report (read-only), or generate a publication-quality schematic via an LLM image API.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `score` | `calculate_scores` | read-only / safe — stdlib-only weighted averaging + quality-level report |
| `schematic` | `generate_schematic` | LLM image generation — needs `OPENROUTER_API_KEY`, `requests`, and network |

The `score` perk loads a JSON of per-dimension ratings (each 1–5), applies the default (or
supplied) dimension weights, and writes a weighted overall score, quality level, ASCII bar chart,
and prioritised recommendations to `report.txt`. It is pure-stdlib and fully offline.
The `schematic` perk turns a natural-language description into a publication-quality diagram via the
OpenRouter image API (Nano Banana 2) with an iterative Gemini quality review; it requires a network,
the `OPENROUTER_API_KEY` secret, and the `requests` library, so it produces no real artifact offline.

## How to use it
Pick a perk (`score` or `schematic`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scholar-evaluation` — MIT (see LICENSE.txt).
