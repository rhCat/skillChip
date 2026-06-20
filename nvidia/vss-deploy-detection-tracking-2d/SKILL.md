---
skill: vss-deploy-detection-tracking-2d
name: RTVI-CV Detection & Tracking 2D
perks: [deploy, discover-streams, render-box, collect-metrics, synthesize-docker-run, check-container-gpu, clean-cache]
---

# vss-deploy-detection-tracking-2d — RTVI-CV Detection & Tracking 2D

Deploy, debug, and operate the RTVI-CV (Real Time Video Intelligence CV) 2D detection / tracking microservice and drive its REST API.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `deploy` | `load_defaults`, `fetch_resources`, `apply_in_container`, `start_app_in_container`, `add_streams` | destructive (runs Docker, pulls NGC images, launches a GPU perception app, adds live streams) |
| `discover-streams` | `discover_streams` | read-only — deterministic, layout-agnostic enumeration of local `.mp4`/`.mkv` videos into exactly `STREAM_COUNT` unique `(id, url)` stream descriptors |
| `render-box` | `render_box` | pure formatter — render a fixed-width light-box step receipt from body rows |
| `collect-metrics` | `collect_metrics` | read-only — sample `/api/v1/metrics` (+ `nvidia-smi`) N times and print averaged GPU/CPU/RAM + per-stream FPS; degrades gracefully offline |
| `synthesize-docker-run` | `synthesize_docker_run` | read-only — reconstruct the full `docker run …` command for an existing container from `docker inspect`, secrets redacted |
| `check-container-gpu` | `check_container_gpu` | read-only — probe CUDA/NVML inside a running container (`nvidia-smi -L` via `docker exec`) to catch the stale-GPU-handle state |
| `clean-cache` | `clean_engine_cache` | tidy — relocate non-`*.engine`/`*.plan` files out of the TRT engine cache into `.quarantine/`; idempotent, never deletes |

The `deploy` perk runs the full DEPLOY workflow as an ordered sequence: resolve per-use-case defaults (`load_defaults`, the read-only entry step) → fetch + extract NGC model/video assets (`fetch_resources`) → apply in-container pipeline configuration (`apply_in_container`) → launch the perception app and wait for readiness (`start_app_in_container`) → add streams over REST (`add_streams`). Because it pulls images, mutates a container, and launches a GPU service, it is declared `destructive: true` and the executor gates it accordingly.

The remaining perks are the skill's independent, standalone operations — each invocable on its own, each emitting one structured-JSON audit line and writing its artifact under `record_store`. `discover-streams` (filesystem scan), `render-box` (stdin→box), and `clean-cache` (cache tidy, with `DRY_RUN=1`) run fully offline; `collect-metrics`, `synthesize-docker-run`, and `check-container-gpu` target a running instance / container and degrade gracefully (placeholder artifact, exit 0) when the REST endpoint, Docker, or GPU is unavailable.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`USECASE`, `CONTAINER_NAME`, `STREAM_COUNT`) + `record_store`, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `vss-deploy-detection-tracking-2d` (Apache-2.0).
