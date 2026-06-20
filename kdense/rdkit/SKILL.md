---
skill: rdkit
name: RDKit (cheminformatics)
perks: [properties, similarity, substructure]
---

# rdkit — RDKit (cheminformatics)

Analyze a molecule library with RDKit: compute molecular descriptors, run fingerprint-based
similarity screens, and filter by substructure patterns. Each perk reads a molecule file
(`.sdf`/`.mol`, or `.smi`/`.smiles`/`.txt` with one SMILES per line, no title line) and writes a
results CSV under `record_store` — read-only analysis, nothing mutated remotely.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named CSV + the executor run-ledger.
The heavy science library (`rdkit`) is NOT bundled — when it is absent the porter degrades
gracefully (the contract's `output_exists` still holds, leaving a `{}` stub) so governance can be
exercised offline; install `rdkit` (Python ≥3.9) for real results.

## Perks
| perk | tool | nature |
|---|---|---|
| `properties` | `rd_properties` | read-only — descriptor table (MW/LogP/TPSA/HBD/HBA/rings/QED/Lipinski/lead-like) |
| `similarity` | `rd_similarity` | read-only — fingerprint similarity screen (ranked hits above threshold) |
| `substructure` | `rd_substructure` | read-only — SMARTS/SMILES substructure include/exclude filter report |

Every perk is read-only (`destructive: false`): it parses an input molecule file, applies one
independent deterministic operation, and writes a results CSV under `record_store`. No perk mutates
a remote or live service.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars (always `INPUT`; `similarity`
also needs `QUERY`, `substructure` needs `PATTERN`) + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `rdkit` — MIT (see LICENSE.txt).
