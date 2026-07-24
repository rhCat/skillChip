---
skill: toolgate
name: Hermes Toolgate
perks: [read, write, exec, net, delegate, selfmod, run]
---

# toolgate — Hermes Toolgate

The governed surface between the Hermes headless agent (Maria) and the world. It has **two faces**:

**1. The gate's policy surface — effect-class claim perks.** Maria's `govern_gate` maps *every* tool
call to a value-free claim against this skill and POSTs it to govd: `{skill: hermes:toolgate, perk:
<effect class>, var_keys: [TOOL, ARGS_DIGEST, TARGET]}`. The perk ids ARE the effect classes:

| perk | claims | destructive |
|---|---|---|
| `read` | read_file / search / snapshots / catalog reads | no — allows without approval |
| `write` | write_file / patch / memory / cron / process | yes — push_back |
| `exec` | terminal / execute_code | yes — push_back |
| `net` | web / browser_* / mcp_* / send_message | yes — push_back |
| `delegate` | delegate_task (subagent spawn) | yes — push_back |
| `selfmod` | any call that would modify the gate's own code/config | yes — push_back, **never ACL-loosened** |

These perks are **verdict-only**: govd decides, Hermes executes its own handler on `allow` — exod
never runs the claimed tool. The perk's snippet (`hermes_claim`) is just the governed recorder, and
everything that crosses the wire is value-free: a tool NAME, a sha256 ARGS_DIGEST, a coarse TARGET
class. Destructive claims resolve through govd `push_back` → the human approval gate.

**2. The confined terminal — the `run` perk.** When a command actually executes through the governed
channel it goes through `run`, inside the exod sandbox — no network, dropped privileges, only the
cargo workspace bound read-write; **confinement is the guarantee**. What `run` adds is the second,
*un-liftable* layer:

- **The destructive floor** — a conservative denylist that runs **before** the command, in blessed
  (hash-verified) chip code. The agent supplies var *values* (`CMD`/`WORKDIR`/…) and never edits the
  snippet, so no agent-side yolo/permission mode can lift the floor. It refuses the classic
  irrecoverables: recursive `rm` of absolute/home/workspace paths, bare `rm` of `/` `~` `.` `*`,
  `mkfs`/`fsck`, `dd` to a device, redirects to raw devices or system dirs, fork bombs.
- **A pure predicate, proven before every run** — the floor lives in `hermes_floor.sh` as
  `floor_verdict()`, a function that **executes nothing**. Step 1 of the perk
  (`hermes_floor_check`) classifies the **pinned case table** (`floor_cases.txt`, part of the
  hashed src closure) and *refuses the whole run* if the floor misclassifies any case — fail
  closed, before `CMD` is even looked at. The table's first block cases are the two commands the
  pre-fix floor missed on 2026-07-22 (`rm -rf $HOME`, `rm -fr /etc`); they are pinned so that gap
  can never silently reopen.
- **Workspace binding** — `WORKDIR` must resolve inside the cargo workspace; cwd escapes are refused.

The floor **fails toward blocking**: matching runs on a normalized copy of `CMD` (quotes stripped,
whitespace collapsed), so a benign command that merely *contains* a destructive string — like
`echo "rm -rf /"` — is refused. That false positive is accepted; the floor is a small, auditable
table, not a shell parser. A determined bypass is stopped by confinement, not by the regexes.

## What to look out for
Each tool prints one JSON status line. `hermes_claim`: `{effect, claimed_tool, args_digest, target}`
mirrored to `claim.json`. `hermes_floor_check`: `{status: ok|refused, fails, total, report}` — a
`refused` here means the floor itself failed its proof (do NOT lift it; fix the floor).
`hermes_exec`: `{status: ok, exit, workdir, out, bytes}` with the command's own exit code inside, or
`{status: blocked, floor: <reason>}` (exit 3) when the floor or the workspace boundary refused.
LOGS TO CHECK: `claim.json` / `floor_report.json` / `exec.out` + the executor run-ledger.

## Perks
| perk | tools | nature |
|---|---|---|
| `read` `write` `exec` `net` `delegate` `selfmod` | `hermes_claim` | verdict-only effect-class claims — value-free recorder |
| `run` | `hermes_floor_check` → `hermes_exec` | prove the floor, then run one command line confined — **destructive** (runs agent-supplied commands; safe only inside the exod sandbox) |
