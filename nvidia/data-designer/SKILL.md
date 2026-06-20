---
skill: data-designer
name: Data Designer
perks: [inspect]
---

# data-designer — Data Designer

Build synthetic datasets with NVIDIA Data Designer. This cartridge ports the
`get_person_object_schema` helper: a read-only inspector that lists a locale's
managed persona fields (PII fields, plus synthetic-persona fields) so you can
wire `person` sampler columns correctly.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `inspect` | `get_person_object_schema` | read-only / safe (reads a locale parquet schema, prints fields) |

## How to use it
Copy `ledger.json` → `task-ledger.json`, set the vars (`LOCALE`) + `record_store`, then
validate → compose → compile → oversight → executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `data-designer` (Apache-2.0).
