---
skill: imagegen
name: Image Generation
perks: [generate, edit, generate-batch]
---

# imagegen — Image Generation

Generate, edit, or batch-generate raster images (photos, illustrations, textures, sprites,
mockups, transparent-background cutouts) through the vendored GPT Image fallback CLI
(`image_gen.py`). Each perk wraps one CLI subcommand; outputs are written locally under
`record_store`.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts
under `record_store`. The porters run the CLI in `--dry-run` mode, which validates the request
and resolves output paths WITHOUT calling the live Image API and WITHOUT requiring
`OPENAI_API_KEY` — so the request preview always lands in the named report even offline. A real
render requires `OPENAI_API_KEY` and the `openai` SDK (plus Pillow for `--downscale-max-dim`).
LOGS TO CHECK: that JSON line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `generate` | `img_generate` | local-output / safe (one prompt → image, dry-run preview) |
| `edit` | `img_edit` | local-output / safe (edit input image[s], optional mask, dry-run preview) |
| `generate-batch` | `img_generate_batch` | local-output / safe (JSONL of prompts → many images, dry-run preview) |

The `generate` perk turns one prompt into a new image. The `edit` perk transforms one or more
input images (inpainting, background replacement, transparency, compositing) with an optional PNG
mask. The `generate-batch` perk reads a JSONL job file (one prompt or job object per line) and
fans out concurrent jobs into an output directory. All three are local-output only (they write
image/JSON files; they never push to a remote or mutate a live service), hence `destructive:
false`.

## How to use it
Pick a perk (`generate`, `edit`, or `generate-batch`), copy `ledger.json` → `task-ledger.json`,
fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `imagegen` — Apache-2.0 (see LICENSE.txt).
