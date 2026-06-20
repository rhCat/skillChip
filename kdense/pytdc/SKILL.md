---
skill: pytdc
name: PyTDC (Therapeutics Data Commons)
perks: [load_split, evaluate, benchmark, oracle_score]
---

# pytdc — PyTDC (Therapeutics Data Commons)

Load/split AI-ready drug-discovery datasets, score metrics, run benchmark groups, and evaluate molecules with oracles (read-only).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
PyTDC downloads datasets/oracle weights on first use; when the `tdc` package or its network are
absent the porter degrades gracefully, writing a `{}` (or `{"status":"skipped",...}`) report so the
contract's `output_exists` still holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `load_split` | `tdc_load_split` | read-only — load a dataset and write a train/valid/test split |
| `evaluate` | `tdc_evaluate` | read-only — score predictions vs truth with a standardized metric |
| `benchmark` | `tdc_benchmark` | read-only — run a benchmark group's 5-seed evaluate protocol |
| `oracle_score` | `tdc_oracle_score` | read-only — score SMILES with a molecular oracle |

`load_split` calls `tdc.<problem>.<Task>(name=...).get_split(method=...)` and writes the partitioned
data plus split sizes. `evaluate` wraps `tdc.Evaluator` over a JSON `{y_true, y_pred}` payload.
`benchmark` wraps a `tdc.benchmark_group` `evaluate(...)` over a per-seed predictions payload.
`oracle_score` wraps `tdc.Oracle(name=...)` over a list of SMILES. All four are read-only local
analysis (`destructive: false`); they produce files under `record_store` and never mutate a remote
or live service.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pytdc` — MIT (see LICENSE.txt).
