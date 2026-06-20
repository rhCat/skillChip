---
skill: pymatgen
name: Pymatgen (Materials Genomics)
perks: [convert, analyze, phasediagram]
---

# pymatgen — Pymatgen (Materials Genomics)

Convert and analyze crystal structures (read-only, local file producers) or build a Materials Project phase diagram for a chemical system (read-only; needs `mp-api` + `MP_API_KEY` + network).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.

The cores are vendored pymatgen CLIs. When pymatgen (or `mp-api`) is absent, each porter degrades
gracefully — it pre-creates its output, records the missing dependency, and still exits `0`, so the
contract's `output_exists` holds. Real conversion/analysis/phase-diagram results require `pymatgen`
(and, for `phasediagram`, `mp-api` plus a valid `MP_API_KEY` and network access).

## Perks
| perk | tool | nature |
|---|---|---|
| `convert` | `structure_convert` | read-only — reads one structure file, writes a converted file under `record_store` |
| `analyze` | `structure_analyze` | read-only — symmetry / coordination / composition analysis, exports `analysis.json` |
| `phasediagram` | `phase_diagram` | read-only — queries Materials Project (`mp-api` + `MP_API_KEY` + network), writes a stability report |

`convert` reads a single structure file with automatic format detection and writes it back out in
`OUTPUT_FORMAT`. `analyze` reports composition, lattice parameters, space group / symmetry, and
coordination environment, exporting the structured results to `analysis.json`. `phasediagram` pulls
all entries for a chemical system from the Materials Project, builds the convex hull, lists the
stable phases, and (optionally) reports the energy above hull / decomposition for a composition.
All three are read-only — none mutate a remote or live service — so each is declared `destructive: false`.

## How to use it
Pick a perk (`convert`, `analyze`, or `phasediagram`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pymatgen` — MIT (see LICENSE.txt).
