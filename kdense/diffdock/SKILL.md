---
skill: diffdock
name: DiffDock (molecular docking)
perks: [check_env, prepare_csv, validate_csv, analyze_results]
---

# diffdock — DiffDock (molecular docking)

Prepare/validate DiffDock batch inputs, check the docking environment, and analyze pose-confidence results (all read-only/local). DiffDock predicts protein–small-molecule binding poses and confidence; it does NOT predict binding affinity.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
These perks are the helper-script cores; actual docking (`python -m inference`) requires the upstream
DiffDock repo plus PyTorch/PyG and a GPU and is out of scope here.

## Perks
| perk | tool | nature |
|---|---|---|
| `check_env` | `check_env` | read-only — diagnoses Python, PyTorch/CUDA, PyG, RDKit, ESM, DiffDock checkpoints |
| `prepare_csv` | `prepare_csv` | local — writes a batch-input CSV template with example rows (needs pandas) |
| `validate_csv` | `validate_csv` | read-only — checks columns, file paths, SMILES of a batch CSV (RDKit optional) |
| `analyze_results` | `analyze_results` | read-only — parses pose-confidence scores, ranks/classifies, exports summary CSV (stdlib) |

`check_env` and `analyze_results` are pure-stdlib and run fully offline; `prepare_csv` and
`validate_csv` use pandas (and optionally RDKit). Every porter degrades gracefully when a science
library is absent so the contract's output always exists.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `diffdock` — MIT (see LICENSE.txt).
