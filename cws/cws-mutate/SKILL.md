---
skill: cws-mutate
name: Mutation Testing
perks: [mutate, mut-chain-verifier, mut-snippet-verify, mut-grant-verify, mut-emitter]
---

# cws-mutate — Mutation Testing (V-MUT)

Prove that a gate actually gates. The doctrine (plan v1.1 §4 / R3): *a gate that survives its own
deletion was never a gate.* This skill copies a project to a sandbox, applies one single-token mutation
at a time to a target file, runs the target's test slice, and counts a mutant **killed** when the slice
fails and **survived** when it passes. A survivor is a hole — the test does not actually pin the
behavior the gate depends on.

It has **no external anchor by nature** — mutation survival is self-evident (either the slice caught the
sabotage or it didn't), which is why it is safe to self-host. The honest residue of the whole ladder
(plan review): a silently-broken harness would report a perfect score, so its OWN self-test (below) feeds
a known-good gate whose slice MUST kill every operator flip — pinning "self-evident" to a fixed check.

## What to look out for
`mutate.json` carries `{target, mutants, killed, survived[], mutation_score, threshold}`. A nonzero exit
means one of: the baseline slice failed on un-mutated code (`reason: baseline_failed` — fix the slice
first), no mutants were generated (`mutants: 0` — nothing to mutate, the target has none of the operator
tokens), or `mutation_score < threshold` (survivors listed by id). LOGS TO CHECK: that line +
`mutate.json` + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `mutate` | `cws_mutate` | mutate a target, run a test slice, score survivors — read-only / safe (operates on a sandbox copy) |
| `mut-chain-verifier` | `cws_chainverify` | R3 gate PINNED to `infra/cwp/chainverify.py` (the Ledger-v2 chain verifier) — score ≥ 0.90 |
| `mut-snippet-verify` | `cws_snippetverify` | R3 gate PINNED to `infra/govern/snippetverify.py` (per-step snippet TOCTOU) — score ≥ 0.90 |
| `mut-grant-verify` | `cws_grantverify` | R3 gate PINNED to `infra/exec/grantverify.py` (Ed25519-DSSE grant verifier, SV-3 spine) — score ≥ 0.90 |

- **`mutate`** — set `PROJECT_DIR` (copied to a sandbox), `TARGET` (file within it), `TEST_CMD` (the
  slice; nonzero exit = killed). Optional `THRESHOLD` (default `0.90`), `MAX_MUTANTS` (default `50`).
- **`mut-chain-verifier` / `mut-snippet-verify`** (P1-T10, SV-2) — the standing R3 gates: `TARGET` +
  `TEST_CMD` are PINNED in the manifesto to a prose-clean executable core + its mutation-pinning slice, so
  the perk encodes which enforcement surface it protects. Set only `PROJECT_DIR` (the repo root). Both
  measure a real **1.0** today.

> Mutation is **whole-file**: against a CLI-bearing module (`__main__`/argparse/print) the score is
> diluted by mutants outside the gate's decision logic, so point `TARGET` at the tightest module that
> holds the gate and read `survived[]` (each id is `token@byte-offset`) to see which mutants lived.
> Function/line-range scoping is future work.

## Scope (buildable now vs the full R3 surface)
The plan's cws-mutate carries one perk per R3 enforcement-surface entry (`mut-authorize-step`,
`mut-oversight`, `mut-snippet-verify`, …). This is the **generic engine**, parameterised by `TARGET` +
`TEST_CMD`; today it can be pointed at the gates that already exist in code — `authorize_step` /
`result_acceptable` (`infra/govern/govd.py`), the tamper check + in-channel oversight gate
(`infra/govern/executor.py`), snippet verification (`infra/govern/govd_client.py`). The per-gate perks
(each pinning its own `TARGET` + slice) are added as each gate's test slice is pinned — the plan's R3
roster fills in here, it does not need a different skill.

## How to use it
Pick `mutate`, copy `ledger.json` → `task-ledger.json`, set `PROJECT_DIR` / `TARGET` / `TEST_CMD` +
`record_store`, then validate → compose → compile → oversight → executor.
