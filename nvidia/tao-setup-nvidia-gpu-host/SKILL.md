---
skill: tao-setup-nvidia-gpu-host
name: NVIDIA GPU Host Setup (TAO)
perks: [setup]
---

# tao-setup-nvidia-gpu-host — NVIDIA GPU Host Setup (TAO)

Standardizes the host GPU runtime before TAO workflows run on the `docker`,
`local-docker`, or `kubernetes` backend: checks (read-only) and, after explicit
user approval, installs NVIDIA driver branch 580, CUDA Toolkit 13.0, NVIDIA
Container Toolkit 1.19.0, and Docker.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `setup` | `setup_nvidia_gpu_host` | destructive — `--install` adds NVIDIA repos, installs system packages, restarts Docker, and adds the user to the `docker` group (the `--check-only` mode is read-only, but the perk can mutate the host) |

The `--check-only` path is universally portable and read-only — it only probes
`nvidia-smi`, the CUDA toolkit path, the container-toolkit package version, and
the Docker daemon's NVIDIA runtime. The `--install` path mutates the host
(system packages, package repos, Docker restart, `docker` group membership) and
needs sudo/root, so the perk is declared `destructive: true`.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars (`BACKEND`, `MODE`) +
`record_store`, then validate → compose → compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `tao-setup-nvidia-gpu-host` (Apache-2.0).
