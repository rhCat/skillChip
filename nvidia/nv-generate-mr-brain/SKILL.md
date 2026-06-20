---
skill: nv-generate-mr-brain
name: NV-Generate-MR-Brain
perks: [generate]
---

# nv-generate-mr-brain — NV-Generate-MR-Brain

Thin governed wrapper over NVIDIA NV-Generate-CTMR's `rflow-mr-brain` image-only synthesis. It stages config overrides, runs the upstream `python -m scripts.diff_model_infer`, and summarizes the generated NIfTI volume. Engineering-time only — output is synthetic and not clinical, not production training data.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `generate` | `run_mr_brain` | destructive (runs GPU diffusion synthesis, may download weights + contact huggingface.co/github.com) |

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`MODEL_CONFIG`, `OUTPUT_DIR`, `MODALITY`, `NV_GENERATE_ROOT`) + `record_store`, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-generate-mr-brain` (Apache-2.0).
