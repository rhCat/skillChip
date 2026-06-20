---
skill: dicom-series-to-volume
name: DICOM Series to Volume
perks: [extract]
---

# dicom-series-to-volume — DICOM Series to Volume

Convert one CT DICOM series folder to a HU NIfTI volume, sorting slices by `ImagePositionPatient`, applying `RescaleSlope`/`RescaleIntercept`, and deriving an affine + axcodes from the DICOM headers. Engineering verification only — not for multi-frame DICOM or clinical use.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `extract` | `series_to_volume` | read-only / safe (local file analysis; writes only to `record_store`) |

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dicom-series-to-volume` (Apache-2.0).
