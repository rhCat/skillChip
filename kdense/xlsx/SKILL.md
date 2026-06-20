---
skill: xlsx
name: Excel Spreadsheets (XLSX)
perks: [recalc, unpack, pack]
---

# xlsx — Excel Spreadsheets (XLSX)

Recalculate Excel formulas (read-only report) or unpack/pack an Office workbook for editing.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report/output + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `recalc` | `recalc` | read-only — recalculate formulas via LibreOffice, scan all cells for Excel errors, emit `recalc.json` |
| `unpack` | `unpack` | read-only on the source — extract a workbook ZIP into a pretty-printed XML tree, emit `unpack.json` |
| `pack` | `pack` | builds a fresh workbook from an XML tree, emit `pack.json` |

The `recalc` perk drives LibreOffice (`soffice`) to evaluate every formula, then reloads the
workbook to count formulas and locate any `#REF!`/`#DIV/0!`/`#VALUE!`/`#NAME?`/`#NULL!`/`#NUM!`/`#N/A`
errors, reporting them as JSON. The `unpack` perk explodes an `.xlsx`/`.docx`/`.pptx` archive into an
editable directory of indented XML. The `pack` perk re-zips an unpacked directory back into an Office
file. All three are file-producing and non-destructive (they never mutate a remote/live service).

## How to use it
Pick a perk (`recalc`, `unpack`, or `pack`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `xlsx` — MIT (see LICENSE.txt).
