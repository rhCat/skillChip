---
skill: clinical-decision-support
name: Clinical Decision Support Documents
perks: [classify, cohort_tables, survival, decision_tree, validate, schematic]
---

# clinical-decision-support — Clinical Decision Support Documents

Stratify biomarker cohorts, build clinical tables / survival statistics / decision-tree
flowcharts, and validate CDS documents. All analysis is read-only and local; the AI schematic
perk is the one network/API-key step.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts
under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
The heavy science libs are vendored-call dependencies, not bundled: when a lib (e.g. `lifelines`,
`scikit-learn`) or `OPENROUTER_API_KEY`/network is absent the porter degrades gracefully — it
still writes its declared output (possibly `{}`) so the contract holds, and records why.

## Perks
| perk | tool | nature |
|---|---|---|
| `classify` | `biomarker_classifier` | read-only — biomarker stratification (PD-L1, HER2, generic threshold) → classified CSV + comparisons |
| `cohort_tables` | `cohort_tables` | read-only — Table 1 / efficacy / safety tables (CSV + LaTeX) |
| `survival` | `survival_analysis` | read-only — Kaplan-Meier + log-rank + Cox HR + at-risk table (needs `lifelines`) |
| `decision_tree` | `decision_tree` | read-only — clinical algorithm spec → TikZ/LaTeX flowchart |
| `validate` | `validate_cds` | read-only — lint CDS doc for sections, citations, GRADE, stats, HIPAA |
| `schematic` | `schematic` | read-only output, but calls OpenRouter (network + `OPENROUTER_API_KEY`) |

`classify`, `cohort_tables`, `decision_tree`, and `validate` run fully offline (pandas/numpy/scipy
or pure stdlib). `survival` needs `lifelines`; absent it, the porter records the gap and writes an
empty report. `schematic` requires `OPENROUTER_API_KEY` and network; absent either, it records the
gap and writes an empty report. None of these perks mutate remote/live state, so all are
`destructive: false`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then
validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `clinical-decision-support` — MIT (see LICENSE.txt).
