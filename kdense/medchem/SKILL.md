---
skill: medchem
name: Medchem (compound triage)
perks: [rules, common_alerts, nibr, alerts, lilly, complexity, query, groups]
---

# medchem — Medchem (compound triage)

Filter and triage compound libraries with medicinal-chemistry rules, structural-alert
catalogs, complexity metrics, chemical-group detection, and the medchem query language.
Each perk reads a molecule file (`.csv`/`.tsv` with a `smiles` column, `.sdf`, or `.txt`
one-SMILES-per-line) and writes a CSV of per-molecule filter results — read-only analysis,
nothing mutated remotely.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named CSV + the executor run-ledger.
The heavy science stack (medchem, datamol, rdkit, pandas) is NOT bundled — when it is absent the
porter degrades gracefully (the contract's `output_exists` still holds) so governance can be
exercised offline; install `medchem datamol pandas tqdm` (and Python ≥3.9) for real results.

## Perks
| perk | tool | nature |
|---|---|---|
| `rules` | `mc_rules` | read-only — drug-likeness rule table (Lipinski/Veber/CNS/...) |
| `common_alerts` | `mc_common_alerts` | read-only — ChEMBL common structural alerts |
| `nibr` | `mc_nibr` | read-only — NIBR screening-deck curation (severity) |
| `alerts` | `mc_alerts` | read-only — named alert catalogs (pains/brenk/tox/...) |
| `lilly` | `mc_lilly` | read-only — Lilly demerits (optional `lilly-medchem-rules` binaries) |
| `complexity` | `mc_complexity` | read-only — ZINC-15 percentile complexity filter |
| `query` | `mc_query` | read-only — medchem query-language pass mask |
| `groups` | `mc_groups` | read-only — chemical-group / substructure detection |

Every perk is read-only (`destructive: false`): it parses an input molecule file, applies one
independent deterministic filter, and writes a results CSV under `record_store`. No perk mutates
a remote or live service. The `lilly` perk additionally needs the optional native
`lilly-medchem-rules` binaries; without them it records nulls rather than failing.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars (always `INPUT`, plus the
perk-specific var such as `RULES`, `ALERTS`, `QUERY`, `COMPLEXITY`, or `GROUPS`) + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `medchem` — MIT (see LICENSE.txt).
