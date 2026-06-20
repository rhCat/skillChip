---
skill: sci-pdf
name: PDF Processing
perks: [check-fillable, extract-fields, extract-structure, render-images, check-boxes, validation-image, fill-fillable, fill-annotations]
---

# sci-pdf — PDF Processing

Inspect, extract, render, and fill PDF documents and forms via governed per-operation perks.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/output file + the executor run-ledger.

Most perks wrap a vendored Python core that imports a heavy PDF library (`pypdf`, `pdfplumber`,
`PIL`, `pdf2image` + poppler). The porters degrade gracefully when the library is absent: they
always (re)create the named output so the contract's `output_exists` holds and exit 0 with an audit
line. `check-boxes` is pure stdlib and runs fully offline.

## Perks
| perk | tool | nature |
|---|---|---|
| `check-fillable` | `check_fillable` | read-only — does the PDF have AcroForm fields? (pypdf) |
| `extract-fields` | `extract_fields` | read-only — dump fillable form-field metadata to JSON (pypdf) |
| `extract-structure` | `extract_structure` | read-only — labels/lines/checkboxes of a non-fillable PDF to JSON (pdfplumber) |
| `render-images` | `render_images` | render PDF pages to PNG images (pdf2image + poppler) |
| `check-boxes` | `check_boxes` | read-only — validate field bounding-box overlaps in a fields JSON (stdlib, hermetic) |
| `validation-image` | `validation_image` | draw field bounding boxes onto a page image (PIL) |
| `fill-fillable` | `fill_fillable` | fill AcroForm fields from a values JSON, write a new PDF (pypdf) |
| `fill-annotations` | `fill_annotations` | overlay FreeText annotations onto a non-fillable PDF, write a new PDF (pypdf) |

Every perk is `destructive: false`: it reads local inputs and writes a new artifact under
`record_store`; none mutate a remote/live service or install anything.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pdf` — MIT (see LICENSE.txt).
