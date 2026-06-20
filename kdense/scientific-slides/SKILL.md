---
skill: scientific-slides
name: Scientific Slides
perks: [slides_to_pdf, pdf_to_images, validate_presentation, generate_slide_image, generate_schematic]
---

# scientific-slides — Scientific Slides

Build, convert, and validate scientific slide decks (read-only/local) or generate slide imagery via an AI service.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
The two `generate_*` perks call the OpenRouter API (Nano Banana / Gemini) and need `OPENROUTER_API_KEY`;
without it (or offline) the porter degrades gracefully, writing a stub report rather than a real image.

## Perks
| perk | tool | nature |
|---|---|---|
| `slides_to_pdf` | `slides_to_pdf` | read-only / local — combine slide images into one PDF (Pillow) |
| `pdf_to_images` | `pdf_to_images` | read-only / local — rasterize a PDF into per-slide images (PyMuPDF) |
| `validate_presentation` | `validate_presentation` | read-only / local — lint a PDF/PPTX/TEX deck (PyPDF2 / python-pptx) |
| `generate_slide_image` | `generate_slide_image` | network — generate a slide/visual via Nano Banana Pro (OpenRouter) |
| `generate_schematic` | `generate_schematic` | network — generate a scientific schematic via Nano Banana 2 (OpenRouter) |

The first three perks are fully local and never reach the network: they read your deck/images and write
a PDF, images, or a validation report under `record_store`. The two `generate_*` perks are thin wrappers
that POST a natural-language prompt to OpenRouter and save the returned image; they require
`OPENROUTER_API_KEY` and are inert (stub output) when the key is absent or the host is offline.
All five perks are declared `destructive: false` — they only ever produce local files.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `scientific-slides` — MIT (see LICENSE.txt).
