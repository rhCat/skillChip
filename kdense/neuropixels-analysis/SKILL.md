---
skill: neuropixels-analysis
name: Neuropixels Analysis (SpikeInterface)
perks: [explore, preprocess, sort, metrics, export_phy, pipeline]
---

# neuropixels-analysis — Neuropixels Analysis (SpikeInterface)

Explore, preprocess, spike-sort, quality-metric, curate, and export Neuropixels
extracellular recordings end-to-end with SpikeInterface (SpikeGLX / Open Ephys / NWB).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its
artifacts under `record_store`. LOGS TO CHECK: that line + the named report + the executor run-ledger.
The science core needs `spikeinterface` (and a sorter such as Kilosort4 — GPU for KS4); when the
library is absent the porter still produces its report file and exits 0 (degraded, audited).

## Perks
| perk | tool | nature |
|---|---|---|
| `explore` | `explore_recording` | read-only — streams, channels, duration, bad channels, signal stats |
| `preprocess` | `preprocess_recording` | local — bandpass + phase-shift + bad-channel removal + CMR, saves preprocessed recording |
| `sort` | `run_sorting` | local — runs a spike sorter (kilosort4 / spykingcircus2 / mountainsort5 / kilosort3) |
| `metrics` | `compute_metrics` | local — SortingAnalyzer + quality metrics + threshold curation (allen/ibl/strict) |
| `export_phy` | `export_to_phy` | local — exports a SortingAnalyzer to Phy for manual review |
| `pipeline` | `neuropixels_pipeline` | local — full load→preprocess→drift→motion→sort→postprocess→curate→export |

All perks are read-only / local-file-producing (`destructive: false`): they read recordings
and write analysis artifacts under `record_store`; none mutates a remote or live service.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `neuropixels-analysis` — MIT (see LICENSE.txt).
