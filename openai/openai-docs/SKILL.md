---
skill: openai-docs
name: OpenAI Docs
perks: [resolve-latest-model, fetch-codex-manual]
---

# openai-docs — OpenAI Docs

Authoritative, current OpenAI developer-docs operations: resolve the latest OpenAI
model and its migration/prompting guide URLs from a docs source, or fetch, verify, and
outline the Codex manual. Both perks are read-only (they read a docs source and write
artifacts under `record_store`); neither mutates a remote service.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
Both cores are Node scripts vendored unchanged into `src/`; the bash porters degrade
gracefully (always pre-create the output file) when `node` or the network is absent.

## Perks
| perk | tool | nature |
|---|---|---|
| `resolve-latest-model` | `resolve_latest_model` | read-only — parse `latestModelInfo` from a local/URL docs source into normalized JSON |
| `fetch-codex-manual` | `fetch_codex_manual` | read-only fetch — HEAD/GET + sha256-verify + temp-cache the Codex manual, emit outline |

`resolve-latest-model` reads `LATEST_MODEL_SOURCE` (a local `latest-model.md`, a `file://`
URL, or an `https://developers.openai.com/...` URL) and writes `latest-model.json` with the
model id, slug, and absolute migration/prompting guide URLs. `fetch-codex-manual` fetches
`https://developers.openai.com/codex/codex-manual.md`, verifies its `x-content-sha256`, caches
it, and writes the heading `outline.md`; it needs live network and degrades to an empty
artifact offline.

## How to use it
Pick a perk (`resolve-latest-model` or `fetch-codex-manual`), copy `ledger.json` → `task-ledger.json`,
fill its vars + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [openai/skills](https://github.com/openai/skills) `openai-docs` — Apache-2.0 (see LICENSE.txt).
