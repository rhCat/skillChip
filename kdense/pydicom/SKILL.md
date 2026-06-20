---
skill: pydicom
name: Pydicom (DICOM medical imaging)
perks: [extract_metadata, convert_image, anonymize]
---

# pydicom — Pydicom (DICOM medical imaging)

Extract DICOM metadata, convert DICOM pixel data to a standard image, or anonymize a DICOM file by stripping PHI — each a read-only / local file producer.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named output file + the executor run-ledger.
All three porters degrade gracefully when `pydicom` (or `numpy`/`Pillow` for image conversion) is not importable — they leave a placeholder so the contract's `output_exists` still holds.

## Perks
| perk | tool | nature |
|---|---|---|
| `extract_metadata` | `extract_metadata` | read-only / safe — reads a `.dcm` and writes its metadata as `text` or `json` |
| `convert_image` | `dicom_to_image` | read-only / safe — converts a `.dcm`'s pixel data to PNG/JPEG/TIFF/BMP |
| `anonymize` | `anonymize_dicom` | read-only on input — writes a NEW de-identified `.dcm` (removes/replaces PHI tags) |

The `extract_metadata` perk runs the vendored `extract_metadata.py` core over `DICOM_IN`, writing `metadata.txt` (or `metadata.json` when `META_FORMAT=json`) under `record_store`. The `convert_image` perk runs the vendored `dicom_to_image.py` core, normalising pixel data and writing the requested image format under `record_store`. The `anonymize` perk runs the vendored `anonymize_dicom.py` core, reading `DICOM_IN` and writing a fresh anonymized `anonymized.dcm` under `record_store` — it never mutates the input or any remote service, so all three are declared `destructive: false`.

## How to use it
Pick a perk (`extract_metadata`, `convert_image`, or `anonymize`), copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pydicom` — MIT (see LICENSE.txt).
