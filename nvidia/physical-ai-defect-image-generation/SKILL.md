---
skill: physical-ai-defect-image-generation
name: Physical AI Defect Image Generation
perks: [generate, preflight-credentials, preflight-pod-template, preflight-urls, pick-best-step]
---

# physical-ai-defect-image-generation — Physical AI Defect Image Generation

End-to-end orchestration of defect image generation, augmentation, and labeling pipelines for AOI (Automated Optical Inspection) datasets on NVIDIA OSMO. The Day 0 path cold-starts with USD-to-ROI, image-edit augmentation, and AnomalyGen; the Day 1 path runs inference and labeling on real images, with optional finetuning to a checkpoint.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `generate` | `render_defect_spec` | destructive — feeds OSMO workflows that submit remotely, train/finetune, and may deploy a local NIM |
| `preflight-credentials` | `preflight_credentials_port` | read-only — checks the OSMO `hf-token` credential and (when `HF_TOKEN` is exported) probes the gated Cosmos HF repos for scope |
| `preflight-pod-template` | `preflight_pod_template_port` | read-only — verifies the OSMO `POD_TEMPLATE` has the nvoptix hostPath mount + `/dev/shm` >= 16 GiB |
| `preflight-urls` | `preflight_urls_port` | read-only — verifies the DIG URL artifacts a `<flow> <usecase>` needs are present under `DIG_URL_ROOT` |
| `pick-best-step` | `pick_best_step_port` | read-only — picks the best anomalygen inference step from a checkpoint tree (argmax avg `nn_score`) |

The governed entry tool `render_defect_spec` is itself a local, read-only render step (it writes the `defect_spec.jsonl` the OSMO `anomaly-infer` stage routes on). The `generate` perk is declared `destructive: true` because the workflow it feeds submits to OSMO, trains/finetunes AnomalyGen checkpoints, and can deploy a Qwen Image-Edit NIM; the executor gates it accordingly.

The four read-only perks expose the skill's independent pre-submit and checkpoint-selection operations: `preflight-credentials` (the `hf-token` gate), `preflight-pod-template` (the nvoptix + dshm template gate), `preflight-urls` (the per-flow URL-artifact checklist run before every submit), and `pick-best-step` (peak-KPI checkpoint selection). The three preflights call the `osmo` CLI and degrade gracefully (recording a non-authoritative report) when it is absent; `pick-best-step` is a pure offline filesystem walk.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`DEFECT_PAIRS`, optional `SPATIAL_DEPENDENCY`) + `record_store`, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `physical-ai-defect-image-generation` (CC-BY-4.0 AND Apache-2.0).
