---
skill: dynamo-recipe-runner
name: Dynamo Recipe Runner
perks: [preflight]
---

# dynamo-recipe-runner — Dynamo Recipe Runner

Discover and lightly validate an existing NVIDIA Dynamo Kubernetes recipe (storage class, image tags, HF secret, GPU hints, router mode) before any cluster-mutating apply. Read-only preflight on the `recipes/` tree.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `preflight` | `recipe_tool` | read-only / safe (local recipe discovery + validation; no kubectl) |

The `preflight` perk runs `recipe_tool.py validate` on a recipe directory and emits the blockers/warnings report (placeholders, missing storage class, HF-secret gaps, GPU count hints) as JSON. It never deploys: the actual `kubectl apply`/`wait`/`port-forward` deploy steps documented in the NVIDIA skill are left to the operator. Because the vendored tool only reads and validates local manifests, the perk is `destructive: false`.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dynamo-recipe-runner` (Apache-2.0).
