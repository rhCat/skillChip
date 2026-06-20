---
skill: pyopenms
name: PyOpenMS (Mass Spectrometry)
perks: [inspect, convert, process_spectra, detect_features_metabo, detect_features_centroided, align_link_quantify, consensus_matrix, detect_adducts, accurate_mass_search, export_gnps, export_sirius, process_identifications, mass_calculator, digest_protein, theoretical_spectrum, extract_chromatograms, plot_ms_data]
---

# pyopenms — PyOpenMS (Mass Spectrometry)

Governed pyOpenMS operations for computational mass spectrometry: inspect and convert MS files,
process spectra, detect and quantify features across samples, annotate adducts and accurate masses,
identify peptides/proteins, and run chemistry and visualization helpers. Each perk wraps one
ready-to-run pyOpenMS CLI as a single deterministic, contract-bound operation.

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts under
`record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger. The heavy
science library (pyOpenMS 3.5.0, requires Python 3.9+) is NOT bundled; if it is absent on the host
each porter degrades gracefully — it still creates its declared output (so the contract holds) and
records the reason in the audit line.

## Perks
| perk | tool | nature |
|---|---|---|
| `inspect` | `inspect_ms_data` | read-only / summary (+ optional per-spectrum CSV) |
| `convert` | `convert_format` | file-producing (mzML/mzXML/MGF) |
| `process_spectra` | `process_spectra` | file-producing (centroid/smooth/normalize/threshold) |
| `detect_features_metabo` | `detect_features_metabo` | file-producing (featureXML + CSV) |
| `detect_features_centroided` | `detect_features_centroided` | file-producing (featureXML + CSV) |
| `align_link_quantify` | `align_link_quantify` | file-producing (consensusXML + quant matrix) |
| `consensus_matrix` | `consensus_to_matrix` | file-producing (quant matrix CSV) |
| `detect_adducts` | `detect_adducts` | file-producing (decharged featureXML) |
| `accurate_mass_search` | `accurate_mass_search` | file-producing (mzTab + CSV) |
| `export_gnps` | `export_gnps` | file-producing (MGF + quant table) |
| `export_sirius` | `export_sirius` | file-producing (.ms + compound TSV) |
| `process_identifications` | `process_identifications` | file-producing (idXML + CSV) |
| `mass_calculator` | `mass_calculator` | read-only report (+ optional isotope CSV) |
| `digest_protein` | `digest_protein` | file-producing (peptide CSV) |
| `theoretical_spectrum` | `theoretical_spectrum` | file-producing (mzML + peak CSV) |
| `extract_chromatograms` | `extract_chromatograms` | file-producing (CSV + optional plot) |
| `plot_ms_data` | `plot_ms_data` | file-producing (PNG/PDF/SVG) |

All perks are local analysis / file-producing and declared `destructive: false`: they read inputs
and write artifacts under `record_store`, never mutating a remote or live service.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`, then
validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pyopenms` — MIT (see LICENSE.txt).
