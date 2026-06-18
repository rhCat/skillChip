---
skill: cws-observe
name: Project Observer
perks: [status, redeem]
---

# cws-observe — Project Observer

The orchestrator/observer: it oversees a task-DAG's progress **against the plan**, and it is honest by
construction — a task is *done* only when it has been **redeemed**, never merely asserted. The plan's
governing rule (milestones doc): *a milestone is redeemed, not asserted — its promise is denominated in a
verifiable artifact.* This skill is where that rule is enforced for the whole swarm: it connects the DAG
to the validators (`cws-*`) and to a tamper-evident **done-ledger**.

- **`status`** reads the swarm (`P*-T*.json` + `_swarm_manifest.json`) and the done-ledger and classifies
  every task — `redeemed` (a chain-verified pass entry), `ready` (validator built + all deps redeemed),
  `blocked:deps`, or `blocked:validator` (its `validated_by` skill isn't built yet). Validator
  availability is read from the **live chip**, so the picture updates itself as validators land. It rolls
  the manifest's milestones (M0–M6) up to closure and names the next pullable tasks.
- **`redeem`** is the only writer of the done-ledger, and it takes no one's word: it records a task's
  redemption **only** when a governed `RUN_LEDGER` shows its validator ran and **passed** (every step ok,
  no refusal event) — appending a `prev`-hash-chained entry `{seq, ts, task_id, validator, verdict,
  evidence_sha, prev}`. A flipped verdict breaks the chain, which `status` reports as `done_ledger_chain:
  broken`. The done-ledger guards itself the same way the run-ledger does.

This closes the loop the rest of the chip opens: the validators grade artifacts, `redeem` turns a passing
governed run into a redemption, and `status` reports progress no one can lie about — the same `quis
custodiet` answer the validators give, applied to the project itself.

## What to look out for
`observe.json` — `{total, counts, next_pullable, validators_available, validators_missing, milestones,
by_task, done_ledger_chain}`. `redeem.json` — `{task_id, validator, verdict, evidence_sha, seq}` or
`verdict: refused` with a reason. A `redeem` refusal (nonzero exit) means the evidence did not show a
clean pass, or it came from the wrong validator. LOGS TO CHECK: that line + the report + the run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `status` | `cws_observe_status` | classify every task by redemption + roll up milestones — read-only / safe |
| `redeem` | `cws_observe_redeem` | append a verified redemption to the done-ledger — writes only the done-ledger |

- **`status`** — set `SWARM_DIR` (+ optional `DONE_LEDGER`). Output: `observe.json`.
- **`redeem`** — set `SWARM_DIR`, `TASK_ID`, `RUN_LEDGER` (+ optional `DONE_LEDGER`). Output: `redeem.json`.

## Scope
Buildable now: it observes the DAG that exists and redeems against the validators that exist (a task whose
validator is unbuilt reads `blocked:validator`). It tracks structural done-state; it does not re-run the
validators (that is each validator's own job, and `redeem`'s evidence). Tightening the validator-identity
binding for evidence that carries no task-ledger, and external done-ledger verification via `cws-ledgercheck`'s
generic chain check, are follow-ups.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then validate →
compose → compile → oversight → executor.
