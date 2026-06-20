---
skill: nemo-evaluator-plugin
name: NeMo Evaluator Plugin
perks: [evaluate]
---

# nemo-evaluator-plugin — NeMo Evaluator Plugin

Run model/agent evaluations against a running NeMo Platform server via the `nemo evaluator`
CLI: feed it an evaluation spec (metrics + dataset + optional target) and run or submit the eval.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `evaluate` | `nemo_evaluator_run` | destructive — submits/runs eval jobs against a remote NeMo Platform |

The `evaluate` perk drives `nemo evaluator evaluate run --spec-file <spec>` (and can submit a
durable job), so it executes evaluations against a live platform and is declared `destructive: true`.
The bundled `generate_example_specs.py` helper (vendored under `src/`) builds an exact-match metric
bundle example and requires the `nemo_evaluator` SDK packages.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars + record_store, then validate → compose →
compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nemo-evaluator-plugin` (Apache-2.0).
