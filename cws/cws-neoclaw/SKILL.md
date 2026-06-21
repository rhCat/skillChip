---
skill: cws-neoclaw
name: Neoclaw — operate a govd node
perks: [discover, run, status]
---

# cws-neoclaw — the agent's governed handle to a govd node

Neoclaw is how an agent **operates a govd node** — its own, or a detached one (the "neoclaw" node) it reaches
over the network. The agent never touches the worker system directly; it speaks to a node's govd through this
skill, and govd does the governing (claim → blessed plan → execution → ledger). The skill is deliberately thin
and **agent-agnostic**: it carries no intelligence and no secrets, just the node address — so any agent, on any
machine, operates any node the same way. This is the client half of the kernel model — the agent KNOWs (reads
what a node governs); every ACT stays a govd syscall on the far side.

## What to look out for
Each perk writes structured JSON to `record_store` and prints a one-line `{"tool":...,"ok":...}` verdict.
`discover` → `discover.json` `{node, reachable, health:{service,mode,chip_sha,runs}, skills[], skill_count, ok}`:
a reachable node returns its identity (which **chip_sha** it runs — so you know *what* it governs) and its
governed catalog. A non-zero exit means the node is down / unreachable — an honest "not operable" signal, with
the reason recorded. LOGS TO CHECK: that line + `discover.json` + the executor run-ledger.

`run` → `run.json` `{node, target:"skill/perk", decision, plan_sha, ledger, ok}`: the node's verdict on a
forwarded sub-claim plus a pointer to the run's ledger. `decision` is `allow` (ran), `push_back` (destructive —
re-submit with `APPROVE`), or `reject`. The node BLESSES + grants every step; the porters run faithfully under
the node's **non-root** identity (the executor's no-root gate). neoclaw carries the verdict, never the task data.

## Perks
| perk | tool | nature |
|---|---|---|
| `discover` | `neoclaw_discover` | GET a node's `/health` + `/catalog` over HTTP — read-only / safe; portable (urllib only) |
| `run` | `neoclaw_run` | forward a governed sub-claim to a node (`run_governed`) — the node blesses + oversees; verdict + ledger returned. Needs a registry matching the node's chip |
| `status` | `neoclaw_status` | GET a node's `/health` — up/down + chip identity, a fast liveness probe — read-only / safe; portable (urllib only) |

- **`discover`** — set `NODE_URL` (a govd base url, e.g. `http://127.0.0.1:5773`). Output: `discover.json`.
- **`run`** — set `NODE_URL` + `SUB_LEDGER` (abs path to the sub-claim task-ledger) + optional `APPROVE`
  (space-separated rule ids for a destructive sub-claim). Output: `run.json`.
- **`status`** — set `NODE_URL`. Output: `status.json` (up/down + node identity).

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, set its vars + `record_store`, then validate →
compose → compile → oversight → executor.

## Scope / coming
`discover` + `status` (read) and `run` (act) are the operate path. Still to come: the node-side **receiving
auth** (caller token + scope) so a *detached* node only accepts scoped, authenticated claims — front a public
node with TLS via a proxy (Caddy) until then, or SSH-tunnel it. Execution is caller-side until the **govd→exod**
server-side dispatch lands; the non-root foundation is already in place (the executor refuses uid 0). Secrets
stay node-side (resolved at the exod boundary, never in the agent's namespace); the agent only ever names
handles, never values.
