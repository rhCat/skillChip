---
skill: nv-generate-mr-brain-finetune
name: NV-Generate MR-Brain Finetune
perks: [finetune]
---

# nv-generate-mr-brain-finetune — NV-Generate MR-Brain Finetune

Finetune the NV-Generate-CTMR `rflow-mr-brain` diffusion UNet from a MONAI-style NIfTI datalist. The wrapper validates the datalist, stages the upstream config glue, and delegates execution to the existing `diff_model_create_training_data` / `diff_model_train` / `diff_model_infer` scripts. Not for clinical, regulatory, or production-data-approval use.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `finetune` | `run_mr_brain_finetune` | destructive (GPU training; pulls model weights; mutates an output tree) |

`--preflight` validates inputs and upstream discovery without launching GPU training; the full run trains the diffusion UNet and is therefore declared `destructive: true`. The executor gates it accordingly.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-generate-mr-brain-finetune` (Apache-2.0).
