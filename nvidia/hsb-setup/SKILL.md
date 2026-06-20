---
skill: hsb-setup
name: Holoscan Sensor Bridge Setup
perks: [setup]
---

# hsb-setup — Holoscan Sensor Bridge Setup

Bring up the NVIDIA Holoscan Sensor Bridge demo end to end: clone the HSB repo,
detect/confirm the supported devkit, configure the host network per platform,
build and run the correct demo container, and verify connectivity by pinging
`192.168.0.2`.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `setup` | `hsb_phase_runner` | destructive (SSH to remote devkit, sudo host/network config, docker build + run) |

The `setup` perk drives the phased bring-up via `scripts/hsb_phase_runner.sh`, which executes
each phase command with timestamped logging. Because it shells out to a remote devkit over SSH,
applies privileged host/network changes, and builds/runs Docker containers, it is declared
`destructive: true`; the executor gates it accordingly.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars (`SSH_TARGET`, `REMOTE_ROOT`, `HSB_PLATFORM`)
+ `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `hsb-setup` (Apache-2.0).
