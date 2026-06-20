---
skill: nv-generate-mr
name: NV-Generate-MR
perks: [generate]
---

# nv-generate-mr — NV-Generate-MR

Generate synthetic body MRI NIfTI volumes by driving NVIDIA-Medtech/NV-Generate-CTMR's
rflow-mr image-only synthesis workflow. The wrapper stages config overrides, runs the
upstream `python -m scripts.diff_model_infer`, then summarizes the generated NIfTI volume.
Image-only (no paired masks); not for production training data or clinical use.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `generate` | `run_mr` | destructive (runs GPU diffusion inference, downloads weights, writes large outputs) |

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-generate-mr` (Apache-2.0).
