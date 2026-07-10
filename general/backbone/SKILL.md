---
skill: backbone
name: Backbone
perks: [validate, tlc, tlaps, preflight]
---

# backbone — prove the bone before writing the flesh

The L++ preflight gate for **spec-first development**: a blueprint (the bone) must pass
`lpp validate` → **TLC** (bounded model check, EMPIRICAL) → **TLAPS** (deductive proof,
AXIOMATIC) *before* its compute units (the flesh) are implemented. This is Emerald §1.1b
made a governed pathway: intelligence at the edges, execution pre-proven.

**This is the standard pattern for all future development:**

1. **Spec as blueprints.** Each component is an L++ blueprint; each decision table is a
   separate ruleset JSON (law-as-data, changed by PR); each test is itself a blueprint
   that DISPATCHes the component as a compute unit. Exemplar: `crucible/docs/spec/shapes/`.
2. **Backbone preflight.** Run `preflight` over the blueprint dir — every blueprint must
   pass all three layers (all-green or fail; empty discovery is a FAIL).
3. **Only then implement** the compute units the blueprints name, accepted by the test
   blueprints' fixtures.

## Perks
- `validate` — layer 1: L++ schema/load validation. `TARGET_BLUEPRINT`.
- `tlc` — layer 2: TLA+ generation + TLC. `TARGET_BLUEPRINT` (+`TLC_TIMEOUT`, default 120s).
- `tlaps` — layer 3: TLAPS proof generation + tlapm discharge. `TARGET_BLUEPRINT`
  (+`TLAPM_TIMEOUT`, default 240s).
- `preflight` — the full matrix over `TARGET_DIR`, recursively; per-file report + summary.

## What to look out for
Each tool writes structured JSON (`backbone_<perk>.json`) into the record store — that
report is the certificate. **Fail-closed everywhere**: a missing prover binary is
status=fail (`missing_tool`), never a silent skip; an empty preflight discovery is a fail.
TLC/TLAPS here prove the **state skeleton** (gate NULL-safety, transition well-formedness,
TypeInvariant induction) with values abstracted — data-level `safety_invariants` are the
compute units' contracts, enforced by the test blueprints at implementation time.

## Blueprint-authoring idioms the solvers enforce
1. Gates NULL-safe in conjunction-first form (`x is not None and …`) or gate on a scalar
   the compute outputs — the TLA generator inits context to NULL and *branches* disjunctions.
2. No comprehensions in gate expressions (untranslatable) — per-element checks are the
   compute unit's contract; the gate reads a scalar.
3. Never name a transition `t_next` — the generated lemma collides with the `Next`
   induction lemma in TLAPS.

## Requirements
`python3` with the `lpp` package importable; `tlc` (+ java) for layer 2; `tlapm` for
layer 3. Nodes lacking a layer's prover refuse that perk (fail-closed) rather than pass.
