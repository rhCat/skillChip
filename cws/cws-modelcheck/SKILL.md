---
skill: cws-modelcheck
name: Model Check
perks: [check, corpus, prove, saga, algebra, workflow, settlement, bisimulation]
---

# cws-modelcheck — Model Check (SV-5 precursor)

Prove the formalism checks what matters: that a blueprint/workflow is free of abstract deadlock before it
runs. Composes `infra/govern/composer` — the pure-Python structural check (non-terminal sinks,
reachability from entry, a reachable terminal) always runs; with `TLA2TOOLS_JAR` + java present, TLC adds
the **EMPIRICAL** certificate over the emitted TLA+. The foundational perks: `check` proves a good blueprint
passes; `corpus` proves the checker actually *catches* known-bad ones (a checker that flags nothing is
useless). The P4 perks (`prove`, `saga`, `algebra`, `workflow`) extend this to all three provers and the
workflow algebra.

## What to look out for
`check` → `modelcheck.json` `{structural[], empirical, status}`: `empirical` is `no_error` (TLC passed),
`skipped` (no JRE — the structural check stands alone, recorded honestly), or `error` (TLC found a
deadlock). `corpus` → `corpus.json` `{cases, caught, missed[]}`: a non-empty `missed` is a hole in the
checker. Nonzero exit = a real blueprint failed (`check`) or a defect slipped through (`corpus`). LOGS TO
CHECK: that line + the report + the executor run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `check` | `cws_check` | structural + TLC on one blueprint — read-only / safe |
| `corpus` | `cws_corpus` | run a known-bad corpus; assert each defect caught — read-only / safe |
| `prove` | `cws_prove` | all 3 provers (P4-T01/T04/T05/T08) — corpus dual-check + EMPIRICAL/SYMBOLIC/AXIOMATIC certs — uses Apalache/TLAPS where installed |
| `saga` | `cws_saga` | failure-as-transitions + saga compensation (P4-T02) — model AND execution |
| `algebra` | `cws_algebra` | workflow algebra (P4-T03) — seq/par compose into a finite product automaton within budget |
| `workflow` | `cws_workflow` | the plan verifies the plan (P4-T09) — the engine pipeline as a deadlock-free workflow |

- **`check`** — set `TARGET_BLUEPRINT` (a `blueprint.json` / `workflow.json`). Output: `modelcheck.json`.
- **`corpus`** — set `CORPUS_DIR` (a dir of known-bad `*.json`). Output: `corpus.json`.

## Scope (the SV-5 surface)
All three certificate classes ship: **EMPIRICAL** (TLC) + the always-on structural check, **SYMBOLIC**
(Apalache), and **AXIOMATIC** (TLAPS) — the `prove` perk gates on all three being present (where the
checkers are installed). The P4 tranche is built: `saga` (failure / compensation), `algebra` (workflow
algebra), and `workflow` (the engine pipeline verified as a deadlock-free workflow). The one remaining item
is the `money` perk (model-checking `settlement.blueprint.json` before a credit exists), not yet built.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, set its var + `record_store`, then validate →
compose → compile → oversight → executor.
