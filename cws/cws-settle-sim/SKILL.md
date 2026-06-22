---
skill: cws-settle-sim
name: Settlement simulator (the money's lifecycle)
perks: [floatban, zerosum, quote, settle, manipulate, dispute, simulate, capstone, pricer, rail, credits, reward-verify, markets, reputation, escrow-expiry, metered-settle]
---

# cws-settle-sim — the SV-6 settlement validator (M6, "the work pays for the work")

cws-settle-sim grades the settlement substrate (`infra/settle/`) — the money's lifecycle from type to ledger
to quote to engine, and onward through the pre-run **pricer**, the settle-time **tax rail**, and **credit**
usage-billing (the Hermes usage-pricing layer). It is built **incrementally** alongside the P6 cone (as
`cws-release` was grown through P3): each perk validates one money-cone capability against its acceptance, on
REAL runs.

## Perks
| perk | task | what |
|---|---|---|
| `floatban` | P6-T01 | **Money type + float-ban** — `infra/settle/money.py` is exact decimal at scale 4, **HALF_EVEN**, and **refuses binary floats** at construction; a `split` re-sums to the total **exactly** (largest-remainder). The float-ban AST lint finds **0** float intrusions in `infra/settle` (and fires on a seed, so the 0 is a real verdict). |
| `zerosum` | P6-T02 | **double-entry reward ledger** — every posting set balances (per-currency zero); an unbalanced set is refused; a **10k-settlement storm** stays globally zero-sum with **escrow zero at every terminal state**; a Merkle **balance root** is committed. |
| `quote` | P6-T04 | **signed funded quote** — govd signs a **plan-bound** quote whose breakdown sums to the amount **exactly**; a priced grant is admitted only with a **funded** quote; tampered / unfunded / plan-mismatched quotes are refused. |
| `settle` | P6-T05 | **settlement engine** — a **dual-signed**, **validation:pass**, **quote-bound** receipt settles atomically (escrow drained to zero, posting balanced, ledger zero-sum, dispute holdback parked); a mutant receipt (signature stripped / verdict flipped / unbound) settles **nothing**. Funding is **per-quote** (escrow keyed by `quote_sha`, so one quote's funds never satisfy another) and settlement is **idempotent** (a re-funded `quote_sha` cannot pay out twice). |
| `manipulate` | P6-T11 | **FMV manipulation resistance** — the index is a trimmed, control-capped, volume-weighted median; 20% adversarial volume at an extreme price moves it **<2%**; sub-admission markets are provisional; sybils under one controller collapse to one. |
| `dispute` | P6-T12 | **dispute lifecycle** — bond → **m-of-n WebAuthn** resolution (reusing the P3 approval artifact) → clawback from holdback (upheld) or bond forfeit (rejected) + reputation delta, all ledgered & zero-sum; <m approvals or a tampered approval does not resolve. |
| `simulate` | P6-T18 | **the authoring** — storm + manipulate + dispute together: zero-sum exact, index drift <2% @ 20% adversarial, dispute lifecycle complete. |
| `capstone` | P6-T21 | **the ladder closes** — cyberware's real redeemed milestones settle as internal-credit bounties (zero-sum), seed the first FMV index, and the plan's completion is a **dual-signed, TSA-anchored** receipt that verifies **offline end-to-end**. |
| `pricer` | price.py (#110) | **plan pricer** — `price_plan` prices a governed run from its **value-free PLAN, before it runs**: context tokens (SKILL.md + blueprint + perk metadata) + output tokens × model rate + tool fee + marketplace %. The itemized subtotal and the total **sum exactly** (Money, scale-4); a seeded `tool_fee` flows into the total; freeform pricing differs from contract pricing; `infra/settle` stays float-clean. |
| `rail` | rails.py (#113) | **settle-time tax rail** — the platform tax is collected **at settle, never as an agent action and never from a hidden portal**: `charge_from_price` splits into substrate / skill-author / marketplace as **visible lines** that re-sum to the total (an over-total split is **refused** — no skim); `LedgerRail`/`StripeRail`/`CreditRail` are pluggable, `StripeRail` stays **inert until keyed**, and `collect_run_tax` settles zero-sum and is **idempotent** per `plan_sha`. |
| `credits` | credits.py (#116) | **credit usage-billing** — a prepaid balance + per-call **debits**, not per-call card fees: a top-up credits the balance, each priced run **debits** its usage tax as a zero-sum posting set, the balance **draws down**, and a run whose tax **exceeds** the balance is **refused** (the structural gate); debits are **idempotent** per `plan_sha`. |
| `reward-verify` | P6-T06 | **money↔work cross-check** — `infra/settle/reward_verify.py` proves the MONEY trail (settlement posting sets) and the WORK trail (dual-signed, validation:pass, quote-bound receipts) are a clean **bijection**: a settlement with no authorizing receipt (`money_without_work`), an authorized receipt never paid (`work_without_money`), or a double-settled quote is flagged — on top of chain + per-record + global zero-sum. |
| `markets` | P6-T10 | **bounty + reverse auction** — a bounty pays **exactly one** validated winner (losers' balances untouched, prize escrow drained to zero, globally zero-sum; refunds the poster when none validate); a **reverse auction** clears at the **lowest qualified** bid at/below the posted ceiling, strictly **below posted** under competition. |
| `reputation` | P6-T13 | **principal reputation** — `infra/settle/reputation.py` computes per-principal scores + a public FMV point from **public ledger data alone** (a third party recomputes them byte-for-byte), Ed25519-**signed** (a tamper breaks it); the `/rep` view is **privacy-gated** — an authenticated counterparty sees per-principal detail, everyone else gets aggregates only. |

## Scope / residuals (stated honestly)
The two value-integrity guards above — **per-quote escrow** and the **spent-quote idempotency guard** — were
added after an adversarial review found that a global escrow pool let one funding satisfy a distinct quote,
and that a re-funded quote could double-pay while staying zero-sum (conservation alone cannot catch a
double-pay). Both now have explicit regression checks. Known honestly-scoped residuals: the demo is
**single-currency** (the invariants are currency-generic); `Money(Decimal(<float>))` is a soft-leak the
scale-4 quantization neutralizes and the float-ban lint keeps `infra/settle` literal-free; and
`release_holdback` has no dispute-window timer or auth yet (it stays balanced and cannot exceed the held
amount) — the timed/authorized release is downstream P6 work.

## Status — the cone is closed
The P6 settlement cone is closed: `simulate` (P6-T18, the formal authoring of storm + manipulate + dispute)
and `capstone` (P6-T21) redeemed **SV-6 — the ladder's top rung**. The `pricer` / `rail` / `credits` perks
extend the validated surface to the Hermes usage-pricing layer (pre-run pricing, the settle-time tax rail,
and credit billing) added on top of the formal cone.
