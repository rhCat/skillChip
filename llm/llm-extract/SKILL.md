---
skill: llm-extract
name: LLM structured extraction (schema-validation payment gate)
perks: [payment-gate]
---

# llm-extract — an `llm/*` intelligence skill class (P6-T09, SV-6)

The first member of the `llm/*` namespace: a metered intelligence skill whose pay is gated on the **shape of
its output**, not merely the **effort** it burned. It makes the P6 doctrine financial —

> **the meter measures effort; the contract decides whether effort was work.**

An LLM step always burns real provider tokens (effort — metered and **exod-attested** in
[`infra/settle/metered.py`](../../../infra/settle/metered.py), pass-through reimbursed per P6-T08). Whether
that effort counts as *work* is decided by this skill's **declared output contract**: a conforming output is
work and earns; a malformed output is effort that produced nothing and earns the publisher **zero**.

## Declared I/O + model class + output contract
All three are declared in [`model.json`](model.json) — the skill's machine-readable contract:

- **input** — `{document: str, schema: dict}` (the text to read + the fields wanted)
- **model class** — `extraction`, a small-tier model with a published token rate (floor/cap clamp lives in
  the metered settle layer)
- **output contract** — `{required: [fields, confidence], types: {fields: dict, confidence: number}}`. The
  output MUST be an object carrying the extracted `fields` and a `confidence`; anything else is not work.

## The payment gate (schema-validation)
Settlement runs through [`infra/settle/intelligence.py`](../../../infra/settle/intelligence.py)
`settle_intelligence`, draining the quote's escrow in **one balanced, zero-sum** posting set, idempotent per
`quote_sha`:

| output vs contract | publisher/agent | initiator | provider (passthrough) | govd (fee) |
|---|---|---|---|---|
| **satisfies** (work) | earns `work` | pays | reimbursed | paid |
| **fails** (effort only) | **zero** | **refunded** `work` per `validation_refund` | **still reimbursed** | **still paid** |

Nobody eats a cost they did not incur; nobody is paid for work they did not deliver. The optional
`validation_refund` penalty (e.g. refund 80 / govd-keep 20) splits the work share **exactly** (no cent lost).

## Perks
| perk | task | what |
|---|---|---|
| `payment-gate` | P6-T09 | Proves the schema-validation payment gate end to end: the settlement gate (`intelligence_selftest` — pass pays work; fail pays the publisher zero, refunds the initiator, yet still pays passthrough + fee; penalty policy exact; zero-sum; idempotent) **and** that THIS skill's own declared output contract discriminates (a conforming sample is work, a malformed one is refused). |

Validated by **alchemy** (the porter's control-flow concords with its declared blueprint, chip-wide).
