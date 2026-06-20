---
skill: hypothesis-generation
name: Scientific Hypothesis Generation
perks: [schematic]
---

# hypothesis-generation — Scientific Hypothesis Generation

Generate an AI publication-quality scientific schematic for a hypothesis report (read-only, network-backed).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + `schematic.json` + the generated
`schematic.png` / `schematic_v*.png` / `schematic_review_log.json` + the executor run-ledger.

The upstream skill is a methodology for formulating testable hypotheses (literature synthesis,
competing-hypothesis generation, quality scoring, experimental design, prediction). Those are
analysis steps an agent performs, not standalone deterministic I/O. The one executable core is the
schematic generator that every hypothesis report is required to call, so it is the cartridge's sole perk.

## Perks
| perk | tool | nature |
|---|---|---|
| `schematic` | `gen_schematic` | read-only / network-backed (AI image generation + quality review via OpenRouter; writes only under `record_store`) |

The `schematic` perk wraps the vendored `generate_schematic.py` -> `generate_schematic_ai.py` cores:
it generates a diagram with the Nano Banana 2 image model, reviews it with a Gemini quality model, and
only regenerates (up to 2 iterations) when the score is below the document-type threshold. It needs the
OpenRouter API (network) and `OPENROUTER_API_KEY`; without them the porter degrades gracefully and still
emits the audit JSON. It mutates nothing outside `record_store`, so it is `destructive: false`.

## How to use it
Pick the `schematic` perk, copy `ledger.json` → `task-ledger.json`, fill `SCHEMATIC_PROMPT`
(plus optional `DOC_TYPE`, `ITERATIONS`, and `OPENROUTER_API_KEY`) and `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `hypothesis-generation` — MIT (see LICENSE.txt).
