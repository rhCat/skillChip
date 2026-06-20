---
skill: latex-posters
name: LaTeX Research Posters
perks: [schematic, review]
---

# latex-posters — LaTeX Research Posters

Generate AI scientific schematic images for research posters, and run a read-only
quality check on a finished poster PDF.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `schematic` | `generate_schematic` | read-only (writes a PNG); calls OpenRouter — needs `OPENROUTER_API_KEY` + network |
| `review` | `review_poster` | read-only / safe (inspects a PDF with poppler tools; degrades gracefully if absent) |

The `schematic` perk wraps `generate_schematic.py` → `generate_schematic_ai.py`, which generates a
scientific diagram with Nano Banana 2 (`google/gemini-3.1-flash-image-preview`) and reviews it with
Gemini for quality; it requires an `OPENROUTER_API_KEY` and network access. The `review` perk runs
the vendored `review_poster.sh` against a PDF, reporting page dimensions, page count, file size, font
embedding and image inventory using poppler utilities (`pdfinfo`, `pdffonts`, `pdfimages`) — read-only,
mutating nothing.

## How to use it
Pick a perk (`schematic` or `review`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `latex-posters` — MIT (see LICENSE.txt).
