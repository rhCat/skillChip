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
`discover` → `discover.json` `{node, reachable, health:{service,mode,chip_sha,runs,exec_mode,exod_attached}, skills[], skill_count, ok}`:
a reachable node returns its identity (which **chip_sha** it runs — so you know *what* it governs), its
**execution mode** (`exec_mode`/`exod_attached` — is it a **govd+exod body** that runs steps delegated/confined,
or a **cooperative anchor** that runs them caller-side), and its governed catalog. A non-zero exit means the
node is down / unreachable — an honest "not operable" signal, with the reason recorded. LOGS TO CHECK: that
line + `discover.json` + the executor run-ledger.

`run` → `run.json` `{node, target:"skill/perk", exec_mode, decision, plan_sha, ledger, ok}`: the node's verdict
on a forwarded sub-claim plus a pointer to the run's ledger. `decision` is `allow` (ran), `push_back`
(destructive — re-submit with `APPROVE`), or `reject`. `run` first reads the node's `exec_mode` and drives the
matching flow — a **delegated body** runs each step via its own **exod** (server-side, confined, signed); a
**cooperative anchor** runs them caller-side. Either way the node BLESSES + grants every step under its
**non-root** identity (the executor's no-root gate). neoclaw carries the verdict, never the task data.

## Perks
| perk | tool | nature |
|---|---|---|
| `discover` | `neoclaw_discover` | GET a node's `/health` + `/catalog` over HTTP — read-only / safe; portable (urllib only) |
| `run` | `neoclaw_run` | forward a governed sub-claim to a node, driving `run_governed` **or** `run_delegated` by the node's `exec_mode` — the node blesses + oversees (a body's exod executes); verdict + ledger returned. Needs a registry matching the node's chip |
| `status` | `neoclaw_status` | GET a node's `/health` — up/down + chip identity + exec_mode, a fast liveness probe — read-only / safe; portable (urllib only) |

**Looking for the govd.** Every perk takes `NODE_URL` — the node's govd base url. This is **your local node**
(`http://127.0.0.1:5773`) *or* a **fleet node's address** (its tailnet `IP:5773`, from your fleet config —
**not** loopback). If `NODE_URL` is unset, the porter falls back to `$GOVD_URL`, then the local node. So name
the node you mean; the skill no longer assumes one hardcoded loopback address.

- **`discover`** — `NODE_URL` (optional — defaults as above). Output: `discover.json`.
- **`run`** — `NODE_URL` (optional) + `SUB_LEDGER` (abs path to the sub-claim task-ledger) + optional `APPROVE`
  (space-separated rule ids for a destructive sub-claim). Output: `run.json`.
- **`status`** — `NODE_URL` (optional). Output: `status.json` (up/down + node identity + exec_mode).

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, set its vars + `record_store`, then validate →
compose → compile → oversight → executor.

## govd + exod
A node is **govd + exod**: govd governs the claim (bless → grant → record); **exod** is the confined limb that
executes. `run` adapts to the node's `exec_mode`:
- **delegated body** — the node's **exod** runs each step server-side, confined (bwrap/runsc, uid 65534), and
  signs the attested status; govd records the signed result. The agent runs **nothing** (`run_delegated`).
  Secrets resolve at the **exod boundary** node-side, never in the agent's namespace — the agent only names
  handles, never values.
- **cooperative anchor** — no limb attached; the steps run caller-side under the node's non-root identity
  (`run_governed`). The non-root gate holds either way (the executor refuses uid 0).

## Scope / coming
Still to come: the node-side **receiving auth** (caller token + scope) so a *detached* node only accepts
scoped, authenticated claims — front a public node with TLS via a proxy (Caddy) until then, or SSH-tunnel it.
A hardened/remote node already requires the agent's principal Bearer token (`GOVD_TOKEN_FILE` — the raw token
never lands in argv).
