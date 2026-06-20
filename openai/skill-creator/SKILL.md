---
skill: skill-creator
name: Skill Creator
perks: [init, gen_openai_yaml, validate]
---

# skill-creator — Skill Creator

Scaffold a new skill from a template, generate its `agents/openai.yaml` UI metadata, or
validate a skill's `SKILL.md` frontmatter — every operation local-only.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
The cores are vendored from `openai/skills` `skill-creator` (`init_skill.py`, `generate_openai_yaml.py`,
`quick_validate.py`); the porters translate env vars → CLI args and degrade gracefully when a dependency is absent.

## Perks
| perk | tool | nature |
|---|---|---|
| `init` | `init_skill` | local-only — scaffolds a new skill dir (SKILL.md + agents/openai.yaml + optional resource dirs) |
| `gen_openai_yaml` | `gen_openai_yaml` | local-only — (re)generates `agents/openai.yaml` for an existing skill dir |
| `validate` | `validate_skill` | read-only — validates a SKILL.md's frontmatter (name/description/naming rules) |

The `init` perk creates a new skill folder at a target path; it vendors `generate_openai_yaml.py` as a
sibling so its `agents/openai.yaml` is written deterministically. `gen_openai_yaml` regenerates that file
on its own for an existing skill. `validate` only reads and inspects — it mutates nothing. All three are
declared `destructive: false` (local file scaffolding / read-only — no remote, live service, or install).

## How to use it
Pick a perk (`init`, `gen_openai_yaml`, or `validate`), copy `ledger.json` → `task-ledger.json`,
fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `skill-creator` — Apache-2.0 (see LICENSE.txt).
