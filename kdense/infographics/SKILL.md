---
skill: infographics
name: Infographics (Nano Banana Pro)
perks: [list_options, generate]
---

# infographics — Infographics (Nano Banana Pro)

List infographic options (read-only) or generate a publication-quality infographic via Nano Banana Pro with Gemini quality review.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `list_options` | `list_options` | read-only / offline (prints types, styles, palettes, thresholds) |
| `generate` | `generate_infographic` | local file-producing; calls OpenRouter (Nano Banana Pro + Gemini review, optional Perplexity research) — needs `OPENROUTER_API_KEY` + network |

The `list_options` perk runs fully offline: it prints the 10 infographic types, 8 industry styles,
3 colorblind-safe palettes, and the per-document-type quality thresholds, capturing them to
`options.txt`. The `generate` perk runs the smart iterative pipeline — optional Perplexity research,
then Nano Banana Pro generation reviewed by Gemini against a document-type threshold, regenerating
only while quality is below threshold — writing the image plus a `*_review_log.json` (and `*_research.json`
when research is enabled) under `record_store`. It produces local files only; it is declared
`destructive: false` (it mutates no remote/live service — it only calls a read-style LLM API).

## How to use it
Pick a perk (`list_options` or `generate`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `infographics` — MIT (see LICENSE.txt).
