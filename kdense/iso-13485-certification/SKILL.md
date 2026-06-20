---
skill: iso-13485-certification
name: ISO 13485 Certification
perks: [gap-analysis]
---

# iso-13485-certification — ISO 13485 Certification

Gap-analyze medical-device QMS documentation against ISO 13485:2016 required procedures (read-only).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report (`gap-report.json`) + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `gap-analysis` | `gap_analyzer` | read-only / safe (scans a docs dir, writes a JSON gap report) |

The `gap-analysis` perk walks `DOCS_DIR` recursively, reads `.txt`/`.md` files (and matches by filename for `.doc`/`.docx`/`.pdf`/`.odt`), keyword-matches each of the ISO 13485:2016 documented procedures and key documents (Quality Manual, MDF, Quality Policy, Quality Objectives), then writes `gap-report.json` with found/missing procedures, a compliance percentage, and prioritized recommendations. It never writes into `DOCS_DIR` — only into `record_store`.

## How to use it
Pick the `gap-analysis` perk, copy `ledger.json` → `task-ledger.json`, fill `DOCS_DIR` + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `iso-13485-certification` — MIT (see LICENSE.txt).
