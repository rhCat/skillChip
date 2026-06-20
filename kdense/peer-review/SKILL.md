---
skill: peer-review
name: Scientific Peer Review
perks: [schematic]
---

# peer-review — Scientific Peer Review

Generate a publication-quality scientific schematic via AI to support manuscript/grant peer review.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `schematic` | `generate_schematic` | read-only / generative (AI diagram generation + iterative quality review) |

The `schematic` perk takes a natural-language `PROMPT` and renders a publication-quality scientific
diagram: it calls Nano Banana 2 (`google/gemini-3.1-flash-image-preview`) to generate the image, then
reviews it with Gemini 3.1 Pro Preview against a document-type quality threshold, regenerating only if
the score is below threshold (max 2 iterations). It writes the image plus a `*_review_log.json` audit
trail under `record_store`. The op needs `OPENROUTER_API_KEY` and network access; offline (or without a
key) the porter degrades gracefully, emitting an empty artifact and a structured audit line — it never
mutates any remote/live service, so it is declared `destructive: false`.

## How to use it
Pick the `schematic` perk, copy `ledger.json` → `task-ledger.json`, fill its vars (`PROMPT`, `OUTPUT`,
`DOC_TYPE`, `OPENROUTER_API_KEY`) + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `peer-review` — MIT (see LICENSE.txt).
