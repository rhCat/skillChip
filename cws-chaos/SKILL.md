---
skill: cws-chaos
name: Chaos drills (partition, crash, settle-atomicity)
perks: [drill, partition, crash, settlecrash]
---

# cws-chaos — fault-injection drills (V-CHAOS, M3/M9)

cws-chaos injects the two faults the governed runtime must survive — a **govd↔exod partition** and an
**exod crash** — plus a **settle-engine crash** mid-posting-set, and asserts the recovery invariants from
`spec/inflight.md`: nothing proceeds ungoverned, nothing is lost, nothing is duplicated, and money is
conserved through a crash.

## Perks
| perk | task | what |
|---|---|---|
| `partition` | P2-T10 | **govd↔exod partition** — the step in flight completes, the next `step_request` **refuses closed** (no fresh grant), and a WS/recorder resume re-delivers the last result **idempotently** (dedup by `(run_id, seq)` → **zero duplicate records**). |
| `crash` | P2-T10 | **crash-exod** — exod dies mid-step: the orphan sandbox is **reaped**, the step records an **error** (never a false pass), and the run is **resumable**. (The real cgroup-kill reap is exercised by the exec-image sandbox tests; this drill asserts the recovery bookkeeping.) |
| `settlecrash` | P6-T17 | **settle-engine crash atomicity** — a crash mid-posting-set is **all-or-nothing** (one record = one append = one fsync; a torn tail is dropped on recovery, never a partial set), recovery **replays exactly once** (the spent-quote guard), and **conservation holds through the crash** (the recovered ledger is zero-sum). |
| `drill` | P2-T10 | all three drills together — the comprehensive V-CHAOS run. |

The core is `infra/chaos.py`; the partition + crash drills are pure stdlib (run in CI), the settle-crash drill
needs openssl (ed25519ph).
