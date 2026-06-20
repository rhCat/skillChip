---
skill: liteparse
name: LiteParse (Local Document Parsing)
perks: [parse, screenshot, batch_parse, search_items]
---

# liteparse — LiteParse (Local Document Parsing)

Parse a document/PDF to layout-preserved text or bbox JSON, render page screenshots, batch-parse a
folder, or phrase-search parsed text items. All processing is local and read-only — no cloud API.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The heavy core
(`liteparse` package / `lit` CLI) is optional at runtime — when absent the porter degrades gracefully
and still writes a (placeholder) artifact so the contract holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `parse` | `lit_parse` | read-only — parse one file/PDF to text or bbox JSON (`lit parse`) |
| `screenshot` | `lit_screenshot` | read-only — render page PNGs for multimodal agents (`lit screenshot`) |
| `batch_parse` | `batch_parse_dir` | read-only — parse every supported file in a directory (vendored script) |
| `search_items` | `search_items` | read-only — phrase-search parsed JSON `text_items`, merge bboxes (stdlib, hermetic) |

`parse` and `screenshot` shell out to the `lit` CLI; `batch_parse` vendors `scripts/batch_parse_dir.py`
unchanged (imports the `liteparse` package); `search_items` is a self-contained stdlib reimplementation
of `liteparse.search_items` that runs offline against a parsed JSON file. Every perk is read-only and
writes outputs under `record_store`.

## How to use it
Pick a perk (`parse`, `screenshot`, `batch_parse`, or `search_items`), copy `ledger.json` →
`task-ledger.json`, fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `liteparse` — MIT (see LICENSE.txt).
