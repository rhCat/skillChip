---
skill: nv-generate-vae-finetune
name: NV-Generate VAE Finetune
perks: [finetune]
---

# nv-generate-vae-finetune — NV-Generate VAE Finetune

Finetune the NV-Generate-CTMR MAISI VAE/autoencoder from a user-supplied CT/MRI NIfTI datalist. Preflight validates the datalist and stages the upstream config/datalist glue; a full run trains adversarially on a single CUDA GPU. Not for clinical, regulatory, or production-data approval.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `finetune` | `run_vae_finetune` | destructive (trains the VAE on a CUDA GPU, may download model weights and write checkpoints) |

The runner validates the MONAI-style datalist (non-empty `training[]` and `validation[]`/`testing[]`), stages `config_maisi_vae_train.json` + `environment_maisi_vae_train.json` from the upstream `NV-Generate-CTMR` checkout, and then runs the skill-owned training loop against upstream transforms/network/utility APIs. `--preflight` stops after validation and staging (no GPU); without it the perk launches real adversarial finetuning, which is why it is declared `destructive: true`.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-generate-vae-finetune` (Apache-2.0).
