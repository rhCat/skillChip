---
skill: holoscan-setup
name: Holoscan SDK Setup
perks: [preflight, check-conda, check-ngc-image]
---

# holoscan-setup — Holoscan SDK Setup

Inspect the host and assess Holoscan SDK install compatibility (read-only): detect Conda
installs even when off PATH, then check whether the NGC Holoscan container image for a CUDA
tag is already pulled — to recommend an install method.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `preflight` | `check_conda`, `check_ngc_image` | read-only / safe (host inspection only — no pulls, installs, or mutations) |
| `check-conda` | `check_conda` | read-only / safe (detect Conda installs even off PATH; report holoscan-importing envs) |
| `check-ngc-image` | `check_ngc_image` | read-only / safe (check whether the NGC Holoscan image for a CUDA tag is pulled) |

The `preflight` perk runs `check_conda` (searches `~/miniconda3`, `~/miniforge3`, `~/anaconda3`,
`~/mambaforge`, `/opt/conda`, and shell rc files, reporting which envs import `holoscan`) then
`check_ngc_image` (greps `docker images` for the `clara-holoscan/holoscan` image matching a CUDA
tag suffix). Both only read host state, so the perk is `destructive: false`.

The single-operation perks expose each inspection on its own: `check-conda` (no inputs; output
`conda.txt`) for Conda detection, and `check-ngc-image` (set `CUDA_TAG_SUFFIX` to one of
`cuda13` / `cuda12-dgpu` / `cuda12-igpu`; output `ngc_image.txt`) for the NGC image check. All
three perks are read-only host inspection — `destructive: false`.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars + record_store, then validate → compose →
compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `holoscan-setup` (Apache-2.0).
