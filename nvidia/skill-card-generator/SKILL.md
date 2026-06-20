---
skill: skill-card-generator
name: Skill Card Generator
perks: [generate, discover-assets, render-card, validate-submission]
---

# skill-card-generator — Skill Card Generator

Draft an NVIDIA governance skill card for an existing agent skill: discover source
signals (read-only, redacted), render a deterministic markdown card from the Jinja
template, and check that human-review (VERIFY/SELECT) markers were removed before submission.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `generate` | `discover_assets`, `render_card`, `validate_submission` | read-only / safe (full pipeline: local file discovery + deterministic render + marker grep) |
| `discover-assets` | `discover_assets` | read-only / safe (bounded, redacted signal report over a target skill dir) |
| `render-card` | `render_card` | read-only / safe (validate context JSON + deterministic Jinja render) |
| `validate-submission` | `validate_submission` | read-only / safe (grep a rendered card for leftover VERIFY/SELECT markers) |

`generate` runs the full sequence end to end; the other three expose each independent stage on its
own so signals can be inspected, a context rendered, or an edited card re-checked without re-running
the whole pipeline. Every perk only reads the target skill directory (credential files are skipped and
secret-like values redacted) and writes its outputs (discovery report, context, rendered card,
validation report) under `record_store`. None mutates the source skill, signs, or publishes a card,
so all are declared `destructive: false`.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `skill-card-generator` (CC-BY-4.0 AND Apache-2.0).
