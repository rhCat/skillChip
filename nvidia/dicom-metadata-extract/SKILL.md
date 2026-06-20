---
skill: dicom-metadata-extract
name: DICOM Metadata Extract
perks: [extract]
---

# dicom-metadata-extract — DICOM Metadata Extract

Extract selected metadata from one DICOM file with pydicom and flag standard-tag PHI presence. Engineering-time only — NOT a de-identifier and NOT for clinical use.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `extract` | `extract_metadata` | read-only / safe (reads one DICOM header, writes one JSON report) |

The `extract` perk reads a single DICOM file header (`stop_before_pixels=True`), emits grouped study/series/image metadata plus `transfer_syntax`, `modality`, `phi_present`, and `phi_tags_found`. It only checks a small PS3.15-inspired standard-tag subset; private tags and burnt-in pixel PHI are out of scope.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `dicom-metadata-extract` (Apache-2.0).
