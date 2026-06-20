---
skill: aiq-research
name: AI-Q Research
perks: [research]
---

# aiq-research — AI-Q Research

Run deep research or AI-Q research through a reachable NVIDIA AI-Q Blueprint backend
(default `http://localhost:8000`) via the helper script `scripts/aiq.py`.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `research` | `aiq` | safe — research client (submit job, poll, fetch report); calls a reachable AI-Q backend over the network |

The `research` tool submits an async deep-research job to the configured `AIQ_SERVER_URL`,
polls until the job reaches a terminal state, and prints the final report JSON. It is a
research client only: it never deploys, starts, stops, or mutates a backend (that is
`aiq-deploy`). User query text is transmitted to the configured backend, so the endpoint
must be trusted before sending sensitive information.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars + record_store, then validate → compose → compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `aiq-research` (Apache-2.0).
