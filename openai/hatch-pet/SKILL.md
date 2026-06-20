---
skill: hatch-pet
name: Hatch Pet
perks: [prepare-run, extract-frames, inspect-frames, validate-atlas, compose-atlas, contact-sheet, render-previews, derive-running-left]
---

# hatch-pet — Hatch Pet

Prepare, extract, inspect, validate, compose, and QA-render Codex-compatible animated pet
spritesheets. Every perk is local-only and deterministic — image generation itself is
delegated elsewhere; these perks only do the deterministic spritesheet plumbing.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/asset + the
executor run-ledger. The cores use Pillow (PIL); when a core or its inputs are absent the
porter degrades gracefully and still writes its declared output (`{}` placeholder).

## Perks
| perk | tool | nature |
|---|---|---|
| `prepare-run` | `prepare_run` | local-only — scaffolds a run folder, prompts, layout guides, job manifest |
| `extract-frames` | `extract_frames` | local-only — chroma-key + slice row strips into 192x208 frames |
| `inspect-frames` | `inspect_frames` | read-only QA — geometry/alpha/chroma report over extracted frames |
| `validate-atlas` | `validate_atlas` | read-only QA — validates an 8x9 atlas (size, alpha, used/unused cells) |
| `compose-atlas` | `compose_atlas` | local-only — composes/normalizes an atlas PNG (+WebP) |
| `contact-sheet` | `contact_sheet` | local-only — renders a labeled QA contact-sheet PNG |
| `render-previews` | `render_previews` | local-only — renders per-state animated GIF QA previews |
| `derive-running-left` | `derive_running_left` | local-only — mirrors running-right into running-left, updates the run manifest |

All perks are `destructive: false`: they read inputs and write artifacts under
`record_store` (or into a local run folder). None deploy, push, install, or mutate a live
service. `inspect-frames` and `validate-atlas` are pure read-only QA reports.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `hatch-pet` — Apache-2.0 (see LICENSE.txt).
