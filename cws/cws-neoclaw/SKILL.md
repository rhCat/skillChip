---
skill: cws-neoclaw
name: Neoclaw — operate a govd node
perks: [discover]
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

## Perks
| perk | tool | nature |
|---|---|---|
| `discover` | `neoclaw_discover` | GET a node's `/health` + `/catalog` over HTTP — read-only / safe; needs a reachable node |

- **`discover`** — set `NODE_URL` (a govd base url, e.g. `http://127.0.0.1:5773`). Output: `discover.json`.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, set `NODE_URL` + `record_store`, then validate →
compose → compile → oversight → executor.

## Scope / coming
`discover` is the read path (operate-by-knowing). The act path — `run` (submit a governed claim to the node)
and `status` (node health/liveness) — comes next, and lands on the node-side **receiving auth** (caller token +
scope) so a detached node only accepts scoped, authenticated claims. Secrets stay node-side (resolved at the
exod boundary, never in the agent's namespace); the agent only ever names handles, never values.
