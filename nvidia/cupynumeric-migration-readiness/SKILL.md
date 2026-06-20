---
skill: cupynumeric-migration-readiness
name: cuPyNumeric Migration Readiness
perks: [assess]
---

# cupynumeric-migration-readiness — cuPyNumeric Migration Readiness

Pre-migration readiness assessor: a static, read-only check of whether existing NumPy code will scale on cuPyNumeric (Legate/GPU) before engineer-weeks are spent porting. The one executable artifact refreshes the bundled NumPy-vs-cuPyNumeric API-support manifest the assessment cross-references.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `assess` | `fetch_api_support` | read-only / safe (scrapes the upstream API comparison table into a markdown manifest; no install, no GPU, no code execution) |

The assessment itself is performed by reading the user's source with Read/Grep and reasoning against the bundled references and the API-support manifest — it never runs the user's code, mutates files, or requires cuPyNumeric installed. The only executable is `fetch_api_support.py`, the user-run refresher for the API-support snapshot (Python stdlib only).

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `cupynumeric-migration-readiness` (Apache-2.0).
