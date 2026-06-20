---
skill: speech
name: Speech (OpenAI TTS)
perks: [list-voices, speak, speak-batch]
---

# Speech (OpenAI TTS)

Generate spoken audio via the OpenAI Audio API using the bundled CLI (`text_to_speech.py`),
defaulting to `gpt-4o-mini-tts-2025-12-15` and built-in voices. Each perk is one independent,
deterministic operation. The `speak` / `speak-batch` perks run in dry-run mode through the
governed channel: they materialize the exact request payload(s) deterministically and never need
network access, so the cartridge self-tests offline. Live audio rendering requires
`OPENAI_API_KEY` plus network and is performed outside the governed run.

## Perks

| Perk | Op | Destructive | Output |
|------|----|-------------|--------|
| `list-voices` | List the built-in TTS voices | no | `voices.txt` |
| `speak` | Preview a single TTS request payload from text | no | `speak.json` |
| `speak-batch` | Preview a batch of TTS request payloads from JSONL | no | `batch.json` |

## How to use

Pick a perk, fill its vars + an absolute `record_store` in a task-ledger, then run it through the governed channel (compiler -> executor).

> Localized from [openai/skills](https://github.com/openai/skills) `speech` — Apache-2.0 (see LICENSE.txt).
