---
skill: nemo-data-designer-plugin
name: NeMo Data Designer
perks: [generate]
---

# nemo-data-designer-plugin — NeMo Data Designer

Build a synthetic dataset with the Data Designer library. The governed tool inspects a locale's managed persona dataset and prints its available PII + synthetic-persona fields, so person-sampling columns can be wired correctly.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `generate` | `get_person_object_schema` | read-only / safe (reads a locale parquet schema, prints fields) |

The `generate` perk inspects the managed persona dataset for one locale (e.g. `en_US`) and reports which PII fields are always available and which synthetic-persona fields appear when `with_synthetic_personas=True`. It only reads a local parquet schema — it never writes or deploys, so it is declared `destructive: false`.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars + record_store, then validate → compose → compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `nemo-data-designer-plugin` (Apache-2.0).
