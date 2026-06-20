---
skill: nv-segment-ct
name: NV-Segment-CT (VISTA3D)
perks: [segment]
---

# nv-segment-ct — NV-Segment-CT (VISTA3D)

Run NVIDIA VISTA3D (132-class CT segmentation foundation model) on a CT NIfTI volume via the official `HuggingFacePipelineHelper`, then record label-map geometry and per-class evidence. Engineering verification only — not for clinical interpretation.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `segment` | `run_vista3d` | local inference / read-only-ish — produces a label-map + evidence JSON, no remote mutation |

The `segment` perk is a thin wrapper: inference, preprocessing, and postprocessing are delegated entirely to the official upstream pipeline in `bundle/`. It runs the model locally, writes a NIfTI mask, and emits a structured JSON summary (input geometry, observed label IDs, unexpected labels, per-class voxel counts and physical volumes, runtime, model identity). It does not deploy, train, finetune, or touch remote infrastructure, so it is declared `destructive: false`.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-segment-ct` (Apache-2.0).
