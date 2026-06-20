---
skill: dynamo-troubleshoot
name: Dynamo Troubleshoot
perks: [troubleshoot]
---

# dynamo-troubleshoot — Dynamo Troubleshoot

Diagnose failed or unhealthy Dynamo Kubernetes deployments by collecting a read-only debug bundle (pods, events, jobs, PVCs, services, `DynamoGraphDeployment` status, and tailed container logs) with secrets scrubbed, so a failure can be turned into a problem class, strongest signal, and next action.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `troubleshoot` | `collect_dynamo_debug_bundle` | read-only / safe |

The `troubleshoot` perk only runs `kubectl get/describe/logs` — it never mutates the cluster, never collects Kubernetes secrets, and redacts HF/bearer tokens before anything is written to disk. Remediation commands are returned to the operator, not executed.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars (`NAMESPACE`, optional `DEPLOYMENT_NAME`) + `record_store`, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dynamo-troubleshoot` (Apache-2.0).
