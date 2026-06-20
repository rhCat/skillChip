---
skill: generate-image
name: Generate Image (AI)
perks: [generate, edit]
---

# generate-image — Generate Image (AI)

Generate a new image from a text prompt, or edit an existing image with an instruction, via OpenRouter image models (FLUX.2, Gemini 3.1 Flash Image Preview).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named output image + the executor run-ledger.
Both perks call the OpenRouter HTTP API and require `OPENROUTER_API_KEY` plus network access; offline
they degrade gracefully (the porter still creates the output file so the contract holds).

## Perks
| perk | tool | nature |
|---|---|---|
| `generate` | `generate_image` | read-only / safe — text prompt → new PNG in `record_store` |
| `edit` | `edit_image` | read-only / safe — input image + instruction → edited PNG in `record_store` |

The `generate` perk turns a text `PROMPT` into a fresh image. The `edit` perk takes an existing
`INPUT_IMAGE` plus an editing `PROMPT` and returns the modified image. Neither mutates any remote or
live service (they only request a render), so both are declared `destructive: false`.

## How to use it
Pick a perk (`generate` or `edit`), copy `ledger.json` → `task-ledger.json`, fill its vars +
`record_store` (and `OPENROUTER_API_KEY`), then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `generate-image` — MIT (see LICENSE.txt).
