---
skill: alchemy
name: Concordance (the alchemy ancestor)
perks: [extract, conserve, classify, concord]
---

# alchemy — concordance validation (P3-T08, the SV-4 ancestor)

alchemy is the **file-mode wrapper** over the concordance engines built in the **putrefactio phase**, pinned
by commit in [`deps.lock`](deps.lock): **putrefactio** (the typestate extractor + leaf-map + conservation
laws) and **alembic** (the declared-blueprint engine + `citrinitas-phase2`). It validates that extracted code
structure is *conserved, named, and concordant with its declared blueprint* — the ancestor every published
skill is graded against. No warehouse / postgres dependency; the engines run on files.

## Perks
| perk | task | what (REAL engine run, no stub) |
|---|---|---|
| `extract` | P3-T08 | **L++ per snippet core** — `python -m python_typestate_extractor <dir>` emits a typestate blueprint (gates / actions / transitions over a `stmt*` block vocabulary) per function. |
| `conserve` | P3-T08 | **conservation** — acquire/release imbalance per resource family vs the `B1_acquire_release_balance` law; `unexplained_defects` = unbalanced families. A clean subject → 0; a real leak (acquire without release) raises it. |
| `classify` | P3-T08 | **classification** — every resource CALL mapped to a named family via the leaf-map; `unnamed` = a CALL with no family. A clean subject → 0; an exotic CALL raises it. |
| `concord` | P3-T08 | **concordance** — the extracted CFG is structurally **contained** in a declared blueprint (the stored diff names any missing state / violating edge). A contained subject passes; an injected undeclared edge is caught. This is **set-containment over the `stmt*` block-order model** — not full control-flow-graph equivalence (see Scope). |

## Scope (stated honestly)
`concord` operates on the **Python L++ layer**: a putrefactio-extracted CFG (Python source) is checked for
containment in a declared blueprint over the **same `stmt*` vocabulary**. Two scope facts, stated plainly so
no reader over-reads the "CFG containment" label:

- **Block-order model, not full CFG equivalence.** `cfg()` models a function as its ordered `stmt*` basic
  blocks; real control structure (loop back-edges, branch merges) is flattened to the linear block sequence
  — the putrefactio blueprint encodes per-block gates/actions, not explicit from→to edges. The containment
  check is genuine (given two real CFGs it catches a removed/extra edge as a diff), but it verifies
  *block-order containment*, not branch-faithful graph isomorphism.
- **`chip_wide_concord` is a drift gate against COMMITTED declared blueprints, not a self-comparison.** Each
  porter's declared CFG is pinned once (`pin_declared` → [`declared/chip-cfgs.json`](declared/chip-cfgs.json),
  an independent committed artifact, exactly as the chip pins file hashes). The check re-extracts each live
  porter and concords it against its pin — so a porter edited after pinning **fails** (drift). The result
  carries a per-run `discriminates` proof (a rogue edge injected into a live CFG is caught vs its pin), so the
  100% rate is never a tautology. Re-pin with `pin_declared` when a porter legitimately changes.
- **Cross-language concord is out of scope.** A Python-extracted CFG against an alembic **Rust**-declared
  blueprint is not attempted: the two extractors never share a source language and no cross-vocabulary bridge
  exists (a Rust typestate extractor would close that gap).

alembic's declared blueprints + `citrinitas-phase2` are wrapped for the declared/Rust side and the
**Citrinitas publish gate** (P3-T09, `cws-release/citrinitas`): verified-tier admission requires
extract + conserve + classify + concord, and a seeded conservation defect, unnamed shape, or CFG mismatch
each blocks publish with its named reason (the mismatch case is a hermetic discriminator — a narrowed
declared blueprint — proving the gate *can* block, not a field-observed rogue edge).

The core is `infra/cwp/alchemy.py`. The perks **SKIP** where the pinned engines are absent (CI) via a
`requires_cmd` probe; they run locally against the checkouts (override paths with `ALCHEMY_PUTREFACTIO` /
`ALCHEMY_ALEMBIC` / `ALCHEMY_CITRINITAS`).
