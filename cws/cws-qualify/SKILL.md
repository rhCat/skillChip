---
skill: cws-qualify
name: Q-Ladder Qualification
perks: [coupon, examine]
---

# cws-qualify — the Q-ladder: standing is earned (Q0–Q3)

How any agent lot earns standing on the bed. A lot never asserts its competence: it runs **coupon**
tasks through the governed channel, and this skill **measures the yield from that evidence** — the
governed run-ledgers, never self-report — into a **Q-record keyed by the lot hash** on a prev-hash-chained
Q-ledger. Rungs: `executor` (run blessed plans — the channel itself qualifies) → `composer` (assemble a
known solution) → `grower` (grow a part that passes the gauntlet) → `examiner` (verdicts on *others'*
work — earned standing **plus lineage independence**, the H6 entrenchment clause) → `releaser` (stays
carbon).

## What to look out for
`coupon.json` carries `{verdict, lot, rung, scope, yield: {coupons, first_pass, scrap, attempts_mean},
coupon_rows[], seq, q_ledger}` — qualification is `scrap == 0 AND first_pass >= MIN_FIRST_PASS`,
fail-closed; a pass appends the Q-record `{lot, rung, scope, ..., evidence_sha, prev}` the ACL layer can
cross-reference (Q2: **scope granted = scope earned**). `examine.json` carries the examiner-gate verdict +
both lots' ancestry. Both perks: the exit code IS the verdict. The Q-ledger chain is re-verifiable by
`cws-ledgercheck/verify`. LOGS TO CHECK: the per-tool JSON line + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `coupon` | `cws_qualify_coupon` | measure a lot's coupon yield from run-ledger evidence → a chained Q-record (writes the Q-ledger) |
| `examine` | `cws_qualify_examine` | examiner-rung gate: earned Q-record (composer+) + lineage independence — read-only |

- **`coupon`** — set `PERFORMER_LOT` (the lot hash) + `COUPONS` (manifest:
  `[{coupon_id, skill, perk, attempts: [run-ledger paths, in order]}]`). Optional `RUNG` (default
  `executor`), `SCOPE`, `MIN_FIRST_PASS` (default 0.8), `Q_LEDGER`.
- **`examine`** — set `PERFORMER_LOT` + `PRODUCER_LOT` + `Q_LEDGER` + `LINEAGE`
  (`{lot: [parent lots]}`). Optional `SCOPE`. Unknown lineage refuses (fail-closed).

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then
validate → compose → compile → oversight → executor.
