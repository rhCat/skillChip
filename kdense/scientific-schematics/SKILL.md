---
skill: scientific-schematics
name: Scientific Schematics (AI)
perks: [generate]
---

# scientific-schematics — Scientific Schematics (AI)

Generate publication-quality scientific diagrams (neural-network architectures, system diagrams, flowcharts, biological pathways, circuits) from a natural-language prompt via OpenRouter — Nano Banana 2 for image generation plus a Gemini quality review with smart iterative refinement.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named diagram PNG + the review-log JSON + the executor run-ledger.
The perk calls the OpenRouter HTTP API and requires `OPENROUTER_API_KEY` plus network access; offline
it degrades gracefully (the porter still creates the output file so the contract holds).

## Perks
| perk | tool | nature |
|---|---|---|
| `generate` | `generate_schematic` | read-only / safe — text prompt → diagram PNG + review-log JSON in `record_store` |

The `generate` perk turns a text `PROMPT` into a publication-quality diagram. Nano Banana 2 generates an
initial image, Gemini reviews it against a document-type quality threshold (`DOC_TYPE`), and only
regenerates (up to `ITERATIONS`, max 2) if quality is below threshold. It only requests a render — it
mutates no remote or live service — so it is declared `destructive: false`.

## How to use it
Pick the `generate` perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`
(and `OPENROUTER_API_KEY`), then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scientific-schematics` — MIT (see LICENSE.txt).
