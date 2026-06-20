---
skill: nv-segment-ctmr
name: NV-Segment-CTMR
perks: [segment]
---

# nv-segment-ctmr — NV-Segment-CTMR

Run the NVIDIA-Medtech NV-Segment-CTMR (VISTA3D) MONAI bundle on a CT or MRI NIfTI volume and record label-map evidence — observed label IDs, per-class voxel counts/volumes, geometry checks, and the upstream command. Engineering verification only; not for clinical interpretation.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `segment` | `run_ctmr` | destructive (shells out to `python -m monai.bundle run`: GPU/CUDA inference, downloads model weights, writes mask outputs) |

The `segment` perk delegates inference entirely to the upstream MONAI bundle under `$NV_SEGMENT_CTMR_ROOT`; it launches the documented `python -m monai.bundle run` entry point and summarizes the produced NIfTI label map. Because it runs a 3D foundation-model inference path (CUDA, weight downloads, multi-GB writes) it is declared `destructive: true`.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nv-segment-ctmr` (Apache-2.0).
