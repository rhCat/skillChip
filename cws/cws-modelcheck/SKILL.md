---
skill: cws-modelcheck
name: Model Check
perks: [check, corpus, prove, saga, algebra, workflow]
---

# cws-modelcheck — Model Check (SV-5 precursor)

Prove the formalism checks what matters: that a blueprint/workflow is free of abstract deadlock before it
runs. Composes `infra/govern/composer` — the pure-Python structural check (non-terminal sinks,
reachability from entry, a reachable terminal) always runs; with `TLA2TOOLS_JAR` + java present, TLC adds
the **EMPIRICAL** certificate over the emitted TLA+. Two perks: `check` proves a good blueprint passes;
`corpus` proves the checker actually *catches* known-bad ones (a checker that flags nothing is useless).

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

- **`check`** — set `TARGET_BLUEPRINT` (a `blueprint.json` / `workflow.json`). Output: `modelcheck.json`.
- **`corpus`** — set `CORPUS_DIR` (a dir of known-bad `*.json`). Output: `corpus.json`.

## Scope (buildable now vs the full SV-5 surface)
EMPIRICAL (TLC) + the always-on structural check exist today. The **SYMBOLIC** (Apalache) and
**AXIOMATIC** (TLAPS) certificate classes, the richer >=6-defect workflow corpus, and the `money` perk
(model-checking `settlement.blueprint.json` before a credit exists) arrive with those checkers and the
workflow algebra (plan P4).

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, set its var + `record_store`, then validate →
compose → compile → oversight → executor.
