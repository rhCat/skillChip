---
skill: transcribe
name: Audio Transcribe
perks: [validate, transcribe]
---

# transcribe — Audio Transcribe

Transcribe audio files to text (or diarized JSON) using OpenAI, with optional speaker
diarization and known-speaker hints. Validate a request first (read-only dry-run), then run it.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `validate` | `transcribe_validate` | read-only / safe (`--dry-run`: validates inputs + emits payload, no API call) |
| `transcribe` | `transcribe_run` | local-only — calls the OpenAI API and writes the transcript to a file under `record_store` |

The `validate` perk runs the bundled CLI in `--dry-run`: it validates the audio file(s), parses
and validates known-speaker references (`NAME=PATH`, max 4), enforces the model/format rules, and
prints the request payload to `payload.json` — it never contacts the API and needs no key. The
`transcribe` perk performs the live transcription and writes the transcript under `record_store`;
it degrades gracefully (emits an empty result) when the `openai` SDK or `OPENAI_API_KEY` is absent.
Neither perk mutates a remote service, so both are `destructive: false`.

## How to use it
Pick a perk (`validate` or `transcribe`), copy `ledger.json` → `task-ledger.json`, fill its vars +
`record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `transcribe` — Apache-2.0 (see LICENSE.txt).
