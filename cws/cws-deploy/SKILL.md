---
skill: cws-deploy
name: Deploy the cyberware engine
perks: [serve, status, down]
---

# cws-deploy — deploy the cyberware govd engine

The dogfood loop closed: a governed skill that deploys the engine that governs it. It
brings up the `cyberware-govd` control/audit plane as a local Docker container — build
the image (if absent), run it, and wait for `/health` — then reports or tears it down.
Requires a reachable Docker daemon.

The container is the **governor**: it blesses value-free plans and records run status. It
never sees your data and never runs your code — the agent runs the blessed porters from its
own verified registry against it. The provenance ledger persists in the data volume across
restarts.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report (`deploy.json` /
`status.json` / `down.json`) + the executor run-ledger. `serve` reports the live `chip_sha`
and the dashboard URL; capture the monitor token from `docker logs <NAME>`.

## Perks
| perk | tool | nature |
|---|---|---|
| `serve` | `deploy_serve` | destructive — (re)creates the container |
| `status` | `deploy_status` | read-only / safe |
| `down` | `deploy_down` | destructive — stops + removes the container (volume preserved) |

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then
validate → compose → compile → oversight → executor. `serve` needs `CONTEXT_DIR` (the repo
root that holds the `Dockerfile`); the rest default `NAME=cyberware`, `PORT=5773`,
`IMAGE=cyberware:local`, `VOLUME=cyberware-govd`.
