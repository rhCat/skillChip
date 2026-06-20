---
skill: pymc
name: PyMC Bayesian Modeling
perks: [diagnostics, diagnostic_report, compare, loo_reliability, model_averaging]
---

# pymc — PyMC Bayesian Modeling

Diagnose, compare, and average Bayesian models from PyMC/ArviZ inference data. Every perk reads
saved `InferenceData` (`.nc` netCDF, as written by `idata.to_netcdf(...)`) and writes its artifacts
under `record_store` — nothing mutates a remote or live service.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The heavy
science libraries (`pymc`, `arviz`) must be importable for real output; when absent the porter still
exits 0 and writes a `{}` placeholder so the contract holds (graceful-offline).

## Perks
| perk | tool | nature |
|---|---|---|
| `diagnostics` | `check_diagnostics` | read-only — R-hat / ESS / divergences / tree depth → `diagnostics.json` |
| `diagnostic_report` | `diagnostic_report` | read-only — trace/rank/autocorr/energy/ESS plots + summary CSV → `report.json` |
| `compare` | `compare_models` | read-only — LOO/WAIC model ranking → `comparison.json` |
| `loo_reliability` | `loo_reliability` | read-only — Pareto-k LOO reliability → `loo_reliability.json` |
| `model_averaging` | `model_averaging` | read-only — pseudo-BMA weights + averaged predictions → `averaging.json` |

`diagnostics` runs `check_diagnostics()` on one `.nc` file and reports convergence flags. `diagnostic_report`
runs `create_diagnostic_report()` to render plots + a summary CSV into `record_store`. `compare`, `loo_reliability`,
and `model_averaging` each take a directory (or comma list) of `.nc` files and run `compare_models()`,
`check_loo_reliability()`, and `model_averaging()` respectively. All are read-only analyses declared
`destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate →
compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pymc` — MIT (see LICENSE.txt).
