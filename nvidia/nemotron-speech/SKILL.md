---
skill: nemotron-speech
name: Nemotron Speech (Riva NIM)
perks: [route]
---

# nemotron-speech — Nemotron Speech (Riva NIM)

Routes an NVIDIA Nemotron Speech (Riva) NIM prompt to the right bundled reference file (ASR / TTS / NMT, setup, readiness, model-selection, pipelines, custom-ASR). A deterministic, read-only classifier — it never deploys, runs, or contacts any GPU/NIM.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `route` | `main` | read-only / safe (regex classifier over the prompt; emits a route JSON) |

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nemotron-speech` (Apache-2.0).
