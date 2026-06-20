---
skill: pymoo
name: pymoo (Multi-Objective Optimization)
perks: [single_objective, multi_objective, many_objective, custom_problem, decision_making]
---

# pymoo — Multi-Objective Optimization in Python

Run pymoo optimization operations as governed, contract-bound perks: single-objective (GA),
multi-objective (NSGA-II), many-objective (NSGA-III), custom problem solving, and multi-criteria
decision making (MCDM) over a Pareto front.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. Every perk is
read-only: it computes a result and writes a report; nothing mutates a remote or live service. The
heavy science library (`pymoo`) is invoked through a vendored Python core; if it is absent the porter
degrades gracefully (emits an empty `{}` report) rather than failing.

## Perks
| perk | tool | nature |
|---|---|---|
| `single_objective` | `pymoo_single_objective` | read-only — GA on a single-objective benchmark, prints best solution |
| `multi_objective` | `pymoo_multi_objective` | read-only — NSGA-II Pareto front on a bi-objective benchmark (ZDT1) |
| `many_objective` | `pymoo_many_objective` | read-only — NSGA-III with reference directions on a many-objective benchmark (DTLZ2) |
| `custom_problem` | `pymoo_custom_problem` | read-only — define + solve custom (constrained + unconstrained) ElementwiseProblems |
| `decision_making` | `pymoo_decision_making` | read-only — MCDM (pseudo-weights) selection from a Pareto front |

All perks force a headless matplotlib backend (`MPLBACKEND=Agg`) so plotting calls never block, and
capture the core's stdout into the named report under `record_store`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pymoo` — MIT (see LICENSE.txt).
