---
skill: vss-deploy-profile
name: VSS Deploy Profile
perks: [deploy, probe-credentials, probe-models, normalize-compose]
---

# vss-deploy-profile — VSS Deploy Profile

Select, configure, deploy, verify, debug, or tear down an NVIDIA VSS compose profile (base, search, lvs, warehouse, edge). Drives the canonical flow: copy `.env` → `generated.env`, apply overrides, dry-run compose into `resolved.yml`, normalize, then `docker compose up -d` and wait for readiness.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `deploy` | `deploy_profile` | destructive (`docker compose up -d` — deploys the VSS stack, pulls NIMs, mutates host infra) |
| `probe-credentials` | `probe_credentials` | read-only (validate NGC / `NVIDIA_API_KEY` / `HF_TOKEN` against their services) |
| `probe-models` | `probe_models` | read-only (GET `BASE_URL/v1/models`, verify the selected model id is advertised) |
| `normalize-compose` | `normalize_compose` | read-only of source (edits a copy of `resolved.yml`, dropping dangling optional `depends_on`) |

The `deploy` perk runs the documented deployment sequence end-to-end: probe credentials/remote endpoints (read-only), resolve compose, strip dangling optional `depends_on` from `resolved.yml`, then bring the stack up. It pulls images, starts containers, and mutates host infrastructure, so it is declared `destructive: true`; the executor gates it accordingly.

The other three perks expose the independent, read-only checks the deploy flow chains, so you can run any of them on its own (a preflight before committing to the destructive `up -d`):
- `probe-credentials` validates the keys a deploy needs against their services so a bad key fails in seconds, not after a cold NIM start. An unset key is a skip (NGC for any local NIM, `NVIDIA_API_KEY` only for remote NIM, `HF_TOKEN` only for edge).
- `probe-models` confirms an OpenAI-compatible remote endpoint advertises the model you intend to point a deploy at (set `BASE_URL`, optional `EXPECTED_MODEL`, and `REMOTE_API_KEY` for authenticated endpoints).
- `normalize-compose` strips the dangling optional `depends_on` entries profile filtering leaves in a resolved compose file — the same Step 3d normalization `deploy` performs inline — operating on a copy so the source artifact is untouched.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`REPO`, `PROFILE`) + `record_store`, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `vss-deploy-profile` (Apache-2.0).
