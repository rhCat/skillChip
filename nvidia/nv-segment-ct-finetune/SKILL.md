---
skill: nv-segment-ct-finetune
name: NV-Segment-CT Finetune
perks: [finetune]
---

# nv-segment-ct-finetune — NV-Segment-CT Finetune

Smoke / sanity / dataset finetuning of NV-Segment-CT VISTA3D on CT NIfTI labels. A thin
auto-configuring wrapper around the upstream MONAI bundle finetune entry. Not for clinical validation.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `finetune` | `run_finetune` | destructive — trains/finetunes a model (GPU, writes checkpoints + configs) |

The wrapper auto-detects GPU + RAM, builds a 5-fold datalist, composes a MONAI override, and runs
`python -m monai.bundle run` (continual-learning finetune). It is `destructive: true` because it trains
a model and mutates the bundle's `configs/` plus the output checkpoint dir; the executor gates it.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-segment-ct-finetune` (Apache-2.0).
