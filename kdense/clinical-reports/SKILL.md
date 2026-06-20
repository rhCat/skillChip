---
skill: clinical-reports
name: Clinical Reports
perks: [validate-case-report, validate-trial-report, check-deidentification, check-compliance, validate-terminology, extract-clinical-data, format-adverse-events, generate-template, generate-schematic]
---

# clinical-reports — Clinical Reports

Validate, de-identify, extract, format, template and illustrate clinical reports — case reports (CARE),
clinical study / adverse-event reports (ICH-E3, SAE), and patient documentation (SOAP, H&P, discharge).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The validators
are advisory regex heuristics — they never edit the input and never fail the step on low compliance; read
the JSON report for findings.

## Perks
| perk | tool | nature |
|---|---|---|
| `validate-case-report` | `validate_case_report` | read-only — CARE section checklist + HIPAA scan + word/reference count → `care_validation.json` |
| `validate-trial-report` | `validate_trial_report` | read-only — ICH-E3 section structure of a CSR → `ich_e3_validation.json` |
| `check-deidentification` | `check_deidentification` | read-only — 18 HIPAA identifiers + ages >89 → `deidentification.json` |
| `check-compliance` | `compliance_checker` | read-only — HIPAA / ICH-GCP / FDA markers → `compliance.json` |
| `validate-terminology` | `terminology_validator` | read-only — Do-Not-Use / ambiguous abbreviations + ICD-10 → `terminology.json` |
| `extract-clinical-data` | `extract_clinical_data` | read-only — demographics + vitals + medications → `clinical_data.json` |
| `format-adverse-events` | `format_adverse_events` | local — AE CSV → per-arm markdown table `ae_summary.md` |
| `generate-template` | `generate_report_template` | local — copy a blank report template → `template.md` |
| `generate-schematic` | `generate_schematic` | network — AI schematic via OpenRouter → `schematic.png` + `schematic.json` (needs `OPENROUTER_API_KEY`) |

All perks are `destructive: false`: the validators/extractors are read-only, the formatter/templater write
new local files, and the schematic generator calls a remote read/generate API (it mutates no live state).
`generate-schematic` is the only non-hermetic perk — it needs an API key, the `requests` library and network;
its in-skill test ships a `skip`. Every other perk runs offline on `python3` stdlib only.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `clinical-reports` — MIT (see LICENSE.txt).
