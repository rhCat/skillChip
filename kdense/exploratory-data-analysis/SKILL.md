---
skill: exploratory-data-analysis
name: Exploratory Data Analysis (scientific files)
perks: [detect_type, format_reference, analyze]
---

# exploratory-data-analysis — Exploratory Data Analysis (scientific files)

Detect, reference, and analyze 200+ scientific data file formats — read-only EDA producing a
markdown report. Covers chemistry, bioinformatics, microscopy, spectroscopy, proteomics,
metabolomics, and general scientific data.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

Every perk is read-only: it reads the input file (or just its name) and writes local files only —
nothing is mutated. `detect_type` and `format_reference` are pure stdlib and run anywhere python3
is present. `analyze` performs format-specific data analysis that needs the matching science
library (numpy/pandas for tabular & arrays — present here; biopython for sequences; pillow for
images; h5py for HDF5). When a library is absent the core degrades gracefully — the markdown report
is still produced with the missing-library note captured in its Data Analysis section, so a governed
run never aborts mid-sequence.

## Perks
| perk | tool | nature |
|---|---|---|
| `detect_type` | `eda_detect_type` | read-only — extension -> category + description + basic metadata -> `file_type.json` |
| `format_reference` | `eda_format_reference` | read-only — vendored reference section for the extension -> `format_reference.md` |
| `analyze` | `eda_analyze` | read-only — full EDA pipeline -> `eda_report.md` |

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars (`DATA_FILE`) + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `exploratory-data-analysis` — MIT (see LICENSE.txt).
