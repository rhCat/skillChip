---
skill: pptx
name: PowerPoint (PPTX)
perks: [extract, thumbnail, render_pdf, unpack, pack, add_slide, clean, validate]
---

# pptx — PowerPoint (PPTX)

Extract, render, unpack/pack, edit, clean, and validate PowerPoint .pptx files.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/file + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `extract` | `extract` | read-only — text/markdown extraction via `markitdown` |
| `thumbnail` | `thumbnail` | read-only — labeled JPEG thumbnail grid (`soffice` + `pdftoppm` + Pillow) |
| `render_pdf` | `render_pdf` | read-only — headless LibreOffice `.pptx` → PDF |
| `unpack` | `unpack` | unpack `.pptx` → pretty-printed XML dir for editing |
| `pack` | `pack` | pack unpacked XML dir → `.pptx` (validation + auto-repair) |
| `add_slide` | `add_slide` | add a slide to an unpacked dir (duplicate or from layout) |
| `clean` | `clean` | remove unreferenced/orphaned files from an unpacked dir |
| `validate` | `validate` | read-only — validate against OOXML XSD schemas |

The read-only perks (`extract`, `thumbnail`, `render_pdf`, `validate`) only inspect inputs and
write derived artifacts to `record_store`. The editing perks (`unpack`, `pack`, `add_slide`,
`clean`) mutate an unpacked working directory or emit a new `.pptx`; none mutates a remote or
live service, so all are declared `destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pptx` — MIT (see LICENSE.txt).
