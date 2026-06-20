---
skill: tao-run-deft-aoi
name: TAO DEFT AOI Loop
perks: [run, analyze-kpi, validate-csv, prepare-pairs, prepare-inference-spec]
---

# tao-run-deft-aoi — TAO DEFT AOI Loop

Run the full DEFT AOI improvement loop for NVIDIA TAO Visual ChangeNet / ChangeNet PCB-inspection
models — baseline evaluate, RCA, ingestion of customer-supplied pre-generated AnomalyGen pairs,
k-NN mining, retraining, and deployment gating — iterating until the FAR / recall KPI target is met.

## Perks
| perk | tool(s) | nature |
|---|---|---|
| `run` | `init_deft_state` | destructive (initializes the loop, then trains / retrains / deploys via docker + GPU) |
| `analyze-kpi` | `analyze_kpi` | read-only (threshold sweep on an inference CSV → FAR @ 100%-recall operating point) |
| `validate-csv` | `validate_training_csv` | read-only (schema + on-disk path + label-case + train/val leakage check on a training CSV) |
| `prepare-pairs` | `changenet_data_pair_prepare` | read-mostly (build the ChangeNet CSV from paired NG/OK image dirs; siamese mode also stages images) |
| `prepare-inference-spec` | `prepare_inference_spec` | read-only (render `best_model.json` + inference spec from a finished run's `deft_state.json`) |

The `run` perk seeds `deft_state.json` (the resume snapshot the loop re-reads from disk before every
stage) and drives the iterative train → inference → evaluate → RCA → ingest → mine → retrain loop. It
trains and retrains TAO Visual ChangeNet, runs containers (`docker run --gpus all`), and gates
deployment — so it is declared `destructive: true` and the executor gates it accordingly.

The other four perks expose the loop's independent deterministic operations on their own, so a user can
invoke any one without running the whole destructive loop:

- `analyze-kpi` sweeps thresholds over a ChangeNet inference CSV (`score > threshold ⇒ NO_PASS`) and
  reports the FAR @ 100%-recall and best-F1 operating points plus per-threshold metrics and plots.
- `validate-csv` checks an assembled ChangeNet training CSV (required columns, on-disk existence of every
  `input_path`/`golden_path`, PASS-preserving label case, and optional train/val leakage) before a GPU run.
- `prepare-pairs` builds the `(input_path, golden_path, label, object_name)` CSV from paired NG/OK image
  directories — minimal 3-column or the 14-column NV_PCB_Siamese layout with image staging.
- `prepare-inference-spec` renders the loop-end handoff (`best_model.json` + `best_model_inference_spec.yaml`)
  from a finished run's `deft_state.json`, picking the lowest-FAR iteration.

## How to use it
Copy `ledger.json` -> `task-ledger.json`, set the vars + record_store, then validate -> compose -> compile -> oversight -> executor.

> Localized from [NVIDIA/skills](https://github.com/NVIDIA/skills) `tao-run-deft-aoi` (Apache-2.0).
