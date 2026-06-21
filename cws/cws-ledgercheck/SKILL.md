---
skill: cws-ledgercheck
name: Ledger Integrity
perks: [verify, anchor, torture, erasure, checkpoint]
---

# cws-ledgercheck — Ledger Integrity (SV-2)

Prove the audit substrate is tamper-evident: that a ledger is a sound provenance chain, not a log someone
trusts. This is the rung where evidence becomes independently re-verifiable. `verify` handles two shapes:
a **Ledger-v2 cryptographic chain** (JSONL / list / `{entries}`) is RE-VERIFIED by recomputing every
record's `prev` as the prior link's RFC-8785 digest (`infra.cwp.ledger.verify_chain`) — a tampered field,
a transplanted genesis, or a deleted record (seq gap) breaks the recompute and the offending record is
named; and the executor's structural **`run-ledger.json`** (the format `infra/govern/executor.py` writes)
is checked for per-step provenance hashes, recognised refusal/waiver events (a recorded refusal is
evidence, meta-rule M4), and **ordering** (the `ok` step records form a contiguous prefix `1..N`).
`anchor` runs the INDEPENDENT Go chain verifier (`verifiers/go chain`) and proves it reproduces
`verify_chain` verdict-for-verdict over a corpus — the external anchor (meta-rule M3) for the chain.

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
| `verify` | `cws_ledgerverify` | recompute a Ledger-v2 prev-chain (tamper/transplant/deletion-evident) or check a structural run-ledger — read-only / safe |
| `anchor` | `cws_ledgeranchor` | build + run the independent Go chain verifier; prove it reproduces `verify_chain` over a corpus (needs `go`) |
| `torture` | `cws_torture` | N concurrent `durable_append` writers must serialize into ONE valid chain, zero lost — destructive (spawns processes + writes a chain) |
| `erasure` | `cws_erasure` | crypto-shredding erasure drill (P1-T07) — destroy a DEK, the chain still verifies, subject fields unrecoverable — read-only / safe |
| `checkpoint` | `cws_checkpoint` | Merkle-checkpoint drill (P1-T03) — window-bounded cold-verify + forged-checkpoint audit — read-only / safe |

- **`verify`** — set `TARGET_LEDGER` (a v2 chain — JSONL/list/`{entries}` — or a `run-ledger.json`).
  Optional `EXPECT_RUN_ID`/`EXPECT_PLAN_SHA` (out-of-band) certify non-transplant; `LEDGER_ALLOW_LEGACY`
  opts into auditing a v1 chain. Output: `ledgercheck.json`.
- **`anchor`** — set `CHAIN_CORPUS` (named v2 chains with `expect_ok`). Output: `anchor.json`.

## Scope (the SV-2 surface)
`verify` recomputes the cryptographic `seq`/`prev` chain of **Ledger-v2** (P1-T01) and `anchor` provides
the external Go cold-verify (P1-T04). Without an out-of-band expected origin the chain is proven only
internally consistent — a chain re-linked under a new genesis would verify clean — which the signed Go
anchor closes. Durability is built: `torture` (N concurrent governed writers serialize into ONE valid
chain), `checkpoint` (Merkle-checkpoint window-bounded cold-verify + forged-checkpoint audit, P1-T03), and
`erasure` (crypto-shredding — a destroyed DEK leaves the chain verifying with subject fields unrecoverable,
P1-T07).

## How to use it
Pick `verify`, copy `ledger.json` → `task-ledger.json`, set `TARGET_LEDGER` + `record_store`, then
validate → compose → compile → oversight → executor.
