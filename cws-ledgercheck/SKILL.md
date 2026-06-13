---
skill: cws-ledgercheck
name: Ledger Integrity
perks: [verify]
---

# cws-ledgercheck — Ledger Integrity (SV-2)

Prove the audit substrate is tamper-evident: that the run-ledger is a sound provenance chain, not a log
someone trusts. This is the rung where evidence becomes independently re-verifiable. The `verify` perk
walks the executor's `run-ledger.json` (the format `infra/govern/executor.py` writes) and checks its
invariants — structure, per-step provenance hashes, recognised refusal/waiver events (a recorded refusal
is evidence, meta-rule M4), and **ordering**: the `ok` step records must form a contiguous prefix `1..N`;
a gap means a step ran out of band, which the chain should never contain.

The recursive twist the plan promises at SV-2 — the checker verifies the ledger of its *own* verification
run — falls out for free: `verify` runs through the executor, so its own run-ledger can be fed back to a
second `verify`.

## What to look out for
`ledgercheck.json` carries `{script, records, bad_records[], chain}`. `chain: "ok"` with an empty
`bad_records` is a clean chain; any entry names the exact defect (a missing `ts`, an `ok` step with no
provenance hash, an ordering gap). A nonzero exit means the chain is broken. LOGS TO CHECK: that line +
`ledgercheck.json` + this run's own run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `verify` | `cws_ledgerverify` | walk a run-ledger; assert structure + ordering — read-only / safe |

- **`verify`** — set `TARGET_LEDGER` (path to a `run-ledger.json`). Output: `ledgercheck.json`.

## Scope (buildable now vs the full SV-2 surface)
Today's run-ledger is a **structural** chain (sequential, recorded, gap-evident) — not yet the
cryptographic `seq`/`prev`/HMAC chain of **Ledger-v2** (plan P1). `verify` checks what exists now; the
`torture` (N concurrent governed writers) and `crashloop` (kill-9 at write offsets) perks — and the
Merkle-checkpoint verification — arrive when Ledger-v2 lands, and the external Go chain-checker becomes
this skill's anchor then.

## How to use it
Pick `verify`, copy `ledger.json` → `task-ledger.json`, set `TARGET_LEDGER` + `record_store`, then
validate → compose → compile → oversight → executor.
