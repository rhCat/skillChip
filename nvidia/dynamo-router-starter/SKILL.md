---
skill: dynamo-router-starter
name: Dynamo Router Starter
perks: [check]
---

# dynamo-router-starter — Dynamo Router Starter

Get a Dynamo router mode running and prove the endpoint works: smoke-test a Dynamo
OpenAI-compatible frontend by hitting `/v1/models` and one `/v1/chat/completions`.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `check` | `check_router_health` | read-only / safe (HTTP GET `/v1/models` + one chat completion) |

The `check` perk only reads from the frontend: it polls `/v1/models` (with retries) and, when a
model is discoverable, issues a single short chat completion. It mutates nothing, so it is declared
`destructive: false`. It is a smoke test, not a benchmark.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars (`BASE_URL`, optional `RETRIES`) + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dynamo-router-starter` (Apache-2.0).
