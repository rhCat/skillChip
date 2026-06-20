---
skill: jupyter-notebook
name: Jupyter Notebook
perks: [scaffold]
---

# jupyter-notebook — Jupyter Notebook

Scaffold a clean, reproducible Jupyter notebook (`.ipynb`) from a bundled template — an `experiment` (exploratory/hypothesis-driven) or a `tutorial` (instructional/step-by-step) layout — instead of hand-authoring raw notebook JSON.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `scaffold` | `new_notebook` | read/local-only — loads a vendored template, sets the title cell, writes a new `.ipynb` |

The `scaffold` perk only reads a bundled template and writes a single notebook file to `record_store`; it never touches a remote, installs anything, or mutates a live service. It is therefore `destructive: false`. The vendored core (`new_notebook.py`) uses only the Python standard library.

## How to use it
Pick the `scaffold` perk, copy `ledger.json` → `task-ledger.json`, fill its vars (`KIND`, `TITLE`, optional `OUT`) + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `jupyter-notebook` — Apache-2.0 (see LICENSE.txt).
