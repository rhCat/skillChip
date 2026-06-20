---
skill: statistical-analysis
name: Statistical Analysis
perks: [normality, homogeneity, linearity, outliers, assumptions]
---

# statistical-analysis — Statistical Analysis

Check statistical assumptions (normality, variance homogeneity, linearity, outliers) before hypothesis testing (read-only). Each perk wraps one deterministic diagnostic from the bundled `assumption_checks.py` core: it reads a CSV, runs the test, writes a JSON report plus a diagnostic PNG under `record_store`.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named JSON report + the executor run-ledger.
All perks are read-only analyses: they read an input CSV and write reports/figures only — they never mutate the input or any remote service.

## Perks
| perk | tool | nature |
|---|---|---|
| `normality` | `check_normality` | read-only — Shapiro-Wilk on one numeric column (+ Q-Q/histogram PNG) |
| `homogeneity` | `check_homogeneity` | read-only — Levene's test across groups (+ box/variance PNG) |
| `linearity` | `check_linearity` | read-only — linear fit + residuals-vs-fitted diagnostic for X vs Y (+ PNG) |
| `outliers` | `detect_outliers` | read-only — IQR or z-score outlier detection on one column (+ box/scatter PNG) |
| `assumptions` | `assumption_check` | read-only — comprehensive workflow: outliers + normality + variance homogeneity |

The diagnostic core (`assumption_checks.py`) depends on numpy / scipy / pandas / matplotlib / seaborn; the porters render figures with the non-interactive `Agg` backend and degrade gracefully (emitting an empty `{}` report) if a dependency is absent.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `statistical-analysis` — MIT (see LICENSE.txt).
