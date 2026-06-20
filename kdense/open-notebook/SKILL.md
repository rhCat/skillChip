---
skill: open-notebook
name: Open Notebook (research API)
perks: [notebook_create, notebook_list, source_add, source_list, chat_session_create, chat_send, search_query, search_ask]
---

# open-notebook — Open Notebook (research API)

Drive a self-hosted [Open Notebook](https://github.com/lfnovo/open-notebook) server (a self-hosted, privacy-preserving NotebookLM alternative) over its REST API: organize research into notebooks, ingest sources, chat with source/note context, and search across the knowledge base. Each perk wraps ONE REST operation against `${OPEN_NOTEBOOK_URL}/api` (default `http://localhost:5055`).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The server must be running and reachable at `OPEN_NOTEBOOK_URL`; when it is unreachable the porter degrades gracefully (writes `{}` / an error payload and exits 0) so the contract still holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `notebook_create` | `notebook_create` | remote-mutating — creates a notebook (POST /api/notebooks) |
| `notebook_list` | `notebook_list` | read-only — lists notebooks (GET /api/notebooks) |
| `source_add` | `source_add` | remote-mutating — ingests a URL/text source (POST /api/sources) |
| `source_list` | `source_list` | read-only — lists sources (GET /api/sources) |
| `chat_session_create` | `chat_session_create` | remote-mutating — creates a chat session (POST /api/chat/sessions) |
| `chat_send` | `chat_send` | remote-mutating — sends a message with context (POST /api/chat/execute) |
| `search_query` | `search_query` | read-only — full-text/vector search (POST /api/search) |
| `search_ask` | `search_ask` | read-only — AI answer over the KB (POST /api/search/ask/simple) |

Read-only perks (`notebook_list`, `source_list`, `search_query`, `search_ask`) only GET/query the server. The create/ingest/chat perks (`notebook_create`, `source_add`, `chat_session_create`, `chat_send`) mutate live server state and are therefore declared `destructive: true`; the executor gates them accordingly.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars (`OPEN_NOTEBOOK_URL` plus the perk's inputs) + `record_store`, then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `open-notebook` — MIT (see LICENSE.txt).
