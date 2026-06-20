---
skill: physical-ai-video-data-augmentation
name: Physical AI Video Data Augmentation
perks: [run, gen-configs, prepare-assets, render-compare]
---

# physical-ai-video-data-augmentation — Physical AI Video Data Augmentation

Orchestrate the end-to-end video data augmentation + auto-labeling workflow on OSMO — flow
selection, credential preflight, submit-time guard, GPU submit, monitoring, and output retrieval.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `run` | `preflight_credentials`, `pre_submit_guard` | destructive (deploys/repairs in-cluster NIMs, submits GPU workflows to OSMO, writes OSMO credentials) |
| `gen-configs` | `generate_configs` | read-only inputs (deterministic per-video augmentation configs + manifest under `record_store`) |
| `prepare-assets` | `prepare_demo_assets` | pulls the VDA demo dataset from Hugging Face and flattens it into one demo input dir |
| `render-compare` | `render_side_by_side` | read-only inputs (side-by-side input-vs-augmented MP4 from a staged local run) |

The `run` perk gates a VDA submit: `preflight_credentials` validates secrets, OSMO credentials, the
control plane (ONLINE GPU pool + GPU `POD_TEMPLATE`), and workflow image access, then `pre_submit_guard`
validates the rendered workflow YAML (setup.files coverage, dataset/cache URLs, VIDEO_NAME basenames)
before any `osmo workflow submit`. Because the workflow deploys NIMs and submits GPU jobs to OSMO, the
perk is declared `destructive: true`; the executor gates it accordingly. Each tool emits one line of
structured JSON and writes its report under `record_store`.

The other three perks are standalone, non-destructive operations that bracket a run:
`gen-configs` runs `generate_configs.py` to deterministically render one Cosmos augmentation config per
input video (plus a `manifest.yaml`) from a pipeline config dir; `prepare-assets` runs
`prepare_demo_assets.sh` to pull the `nvidia/video-data-augmentation-demo` videos from Hugging Face and
flatten them into one demo input directory; and `render-compare` runs `render_side_by_side.sh` to stitch
the original input and the augmented output of a locally-staged run into one side-by-side MP4. Each emits
one structured-JSON line and writes under `record_store`.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`WORKFLOW`) + `record_store`, then
validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `physical-ai-video-data-augmentation` (Apache-2.0).
