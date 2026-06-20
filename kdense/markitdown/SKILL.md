---
skill: markitdown
name: MarkItDown (File to Markdown)
perks: [batch_convert, convert_literature, convert_with_ai, generate_schematic]
---

# markitdown — MarkItDown (File to Markdown)

Convert files and office documents to Markdown (PDF, DOCX, PPTX, XLSX, images, audio, HTML, CSV, JSON, XML, ZIP, EPUB, YouTube) and generate AI-powered scientific schematics. Markdown is token-efficient and LLM-friendly.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/output dir + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `batch_convert` | `batch_convert` | read-only / local — directory of files → Markdown files (needs `markitdown` lib) |
| `convert_literature` | `convert_literature` | read-only / local — PDF dir → Markdown + front-matter + INDEX/catalog (needs `markitdown` lib) |
| `convert_with_ai` | `convert_with_ai` | network — one file → Markdown with AI image descriptions (needs `markitdown` + OpenRouter API key) |
| `generate_schematic` | `generate_schematic` | network — NL prompt → publication-quality diagram (needs OpenRouter API key, Nano Banana 2 + Gemini review) |

`batch_convert` and `convert_literature` are deterministic local conversions: they read input files and write Markdown (plus a JSON catalog / review log) under `record_store`. `convert_with_ai` and `generate_schematic` reach OpenRouter for vision/image models and require `OPENROUTER_API_KEY`; they are still file-producing and declared `destructive: false`. All four porters pre-create their output and degrade gracefully (emitting structured JSON) when the heavy library or API key is absent.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `markitdown` — MIT (see LICENSE.txt).
