---
skill: treatment-plans
name: Treatment Plan Writing
perks: [check_completeness, validate_quality, generate_timeline, generate_template, generate_schematic]
---

# treatment-plans — Treatment Plan Writing

Generate, validate, and visualize concise (3-4 page) LaTeX medical treatment plans across clinical
specialties — general medical, rehabilitation, mental health, chronic disease, perioperative, and
pain management — with SMART goals, HIPAA compliance checks, and AI schematics.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report/figure + the executor run-ledger. The
analysis perks (`check_completeness`, `validate_quality`, `generate_timeline`) are pure-stdlib and
read-only. `generate_template` copies a vendored `.tex` template. `generate_schematic` calls the
OpenRouter API (needs `OPENROUTER_API_KEY` + `requests` + network) and degrades gracefully offline.

## Perks
| perk | tool | nature |
|---|---|---|
| `check_completeness` | `check_completeness` | read-only / stdlib (section + SMART + HIPAA + placeholder audit) |
| `validate_quality` | `validate_quality` | read-only / stdlib (quality + ICD-10 + timeframe + metric audit) |
| `generate_timeline` | `generate_timeline` | read-only / stdlib text timeline (matplotlib optional for visual) |
| `generate_template` | `generate_template` | copies a specialty `.tex` template into `record_store` |
| `generate_schematic` | `generate_schematic` | AI figure via OpenRouter (network + `OPENROUTER_API_KEY`) |

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate →
compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `treatment-plans` — MIT (see LICENSE.txt).
