---
skill: dynamo-interconnect-check
name: Dynamo Interconnect Check
perks: [check]
---

# dynamo-interconnect-check — Dynamo Interconnect Check

Confirm a Dynamo disagg deployment's NIXL/UCX/NCCL transport is actually ready over RDMA/NVLink before trusting disaggregated serving or its benchmarks. Read-only: it never mutates the cluster and never prints secrets.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `check` | `check_interconnect` | read-only / safe |

The `check` perk runs `check_interconnect.py env <recipe_dir>` to inspect the NIXL/UCX/NCCL transport env vars on a recipe (the local, hermetic Step 1). The same script also exposes `node` (probe IB/GPUDirect/NVLink in a pod) and `nixl` (NIXL reachability) subcommands — both read-only, but they need `kubectl exec` into a worker pod.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dynamo-interconnect-check` (Apache-2.0).
