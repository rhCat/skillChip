---
skill: pptx-posters
name: PPTX Research Posters (HTML-based)
perks: [schematic]
---

# pptx-posters — PPTX Research Posters (HTML-based)

Generate AI scientific schematic figures for HTML/PPTX research posters via OpenRouter
(Nano Banana 2 image generation + Gemini quality review). The figures are the AI-generated
visual elements (hero image, methods flowchart, results chart, etc.) the poster assembles.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named output image + the
executor run-ledger. This perk reaches OpenRouter over the network and needs
`OPENROUTER_API_KEY`; absent the key / network / `requests`, the porter degrades gracefully
(empty artifact, exit 0) so the governed run still records cleanly.

## Perks
| perk | tool | nature |
|---|---|---|
| `schematic` | `schematic` | read-only / local-write (calls OpenRouter; writes one image + review log under `record_store`) |

The `schematic` perk wraps `generate_schematic.py` (the launcher) → `generate_schematic_ai.py`
(the AI core): it submits the prompt to Nano Banana 2, runs an iterative Gemini quality review
(thresholds keyed by `DOC_TYPE`, e.g. `poster` 7.0/10, max 2 iterations), and writes the final
PNG plus a `*_review_log.json` into `record_store`. It mutates no remote/live service, so it is
declared `destructive: false`.

## How to use it
Pick the `schematic` perk, copy `ledger.json` → `task-ledger.json`, fill its vars
(`PROMPT`, `OUTPUT_NAME`, optional `DOC_TYPE`/`ITERATIONS`, `OPENROUTER_API_KEY`) + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pptx-posters` — MIT (see LICENSE.txt).
