---
skill: scientific-writing
name: Scientific Writing
perks: [generate_schematic, generate_image]
---

# scientific-writing — Scientific Writing

Generate publication-quality scientific schematics and images for manuscripts via the OpenRouter API.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named output image + the executor run-ledger.

Both perks call the OpenRouter API and require `OPENROUTER_API_KEY`. With no key or no network
the porters degrade gracefully — they still create the declared output (empty placeholder) and
emit their audit line so the contract holds, but produce no real image.

## Perks
| perk | tool | nature |
|---|---|---|
| `generate_schematic` | `generate_schematic` | read-only / network — text prompt → diagram PNG, with Gemini quality-review iteration |
| `generate_image` | `generate_image` | read-only / network — text prompt (+ optional input image) → illustrative PNG |

The `generate_schematic` perk wraps `generate_schematic.py`, which delegates to the vendored
`generate_schematic_ai.py` core: it generates a diagram with Nano Banana 2, reviews it with
Gemini 3.1 Pro Preview, and re-generates (up to 2 iterations) only if quality is below the
document-type threshold. The `generate_image` perk wraps `generate_image.py` for general image
generation or editing. Neither mutates remote/live state, so both are declared `destructive: false`.

## How to use it
Pick a perk (`generate_schematic` or `generate_image`), copy `ledger.json` → `task-ledger.json`,
fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scientific-writing` — MIT (see LICENSE.txt).
