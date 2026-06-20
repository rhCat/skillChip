---
skill: dicom-series-preflight
name: DICOM Series Preflight
perks: [preflight]
---

# dicom-series-preflight — DICOM Series Preflight

Header-only preflight of one DICOM series folder before conversion or inference: inventories instances, derives orientation axcodes, flags standard PHI tags, and emits a `pass`/`warn`/`fail` verdict. Not for de-identification or clinical clearance.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `preflight` | `preflight_series` | read-only / safe (header-only scan; `stop_before_pixels`, no decode, no mutation) |

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dicom-series-preflight` (Apache-2.0).
