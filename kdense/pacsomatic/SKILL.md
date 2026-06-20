---
skill: pacsomatic
name: Pacsomatic (nf-core launcher)
perks: [samplesheet, params, launch-script, dry-run, submit]
---

# pacsomatic — Pacsomatic (nf-core launcher)

Operator toolkit for nf-core/pacsomatic matched tumor/normal workflows from BAM inputs:
build the samplesheet, generate the params YAML and executor launch script, dry-run validate
(read-only), or submit the run (destructive).

## What to look out for
Each tool emits one line of structured JSON (the audit + debug log) and writes its artifacts
under `record_store`. LOGS TO CHECK: that line + the named artifact + the executor run-ledger.
The vendored core (`run_pacsomatic.py`) is pure Python stdlib — no nextflow/conda is needed to
build artifacts or dry-run; only the `submit` perk needs a resolvable runtime + scheduler.

## Perks
| perk | tool | nature |
|---|---|---|
| `samplesheet` | `build_samplesheet` | read-only — writes `samplesheet.csv` (patient,sample,status,bam,pbi) |
| `params` | `build_params` | read-only — writes the generated params YAML (input/outdir + fasta\|genome) |
| `launch-script` | `build_launch_script` | read-only — writes `run_pacsomatic.<executor>.sh` (scheduler headers + nextflow run) |
| `dry-run` | `dry_run` | read-only — validates inputs + deps and writes all artifacts, no execution |
| `submit` | `submit` | destructive (`--run`) — executes locally or submits to LSF/Slurm/PBS/SGE |

The `samplesheet`, `params`, `launch-script`, and `dry-run` perks never execute the pipeline:
they only validate and write files under `record_store`. The `submit` perk launches/submits the
generated script (mutating a live scheduler or running the pipeline) and is declared `destructive: true`;
the executor gates it accordingly.

## How to use it
Pick a perk, copy `ledger.json` → `task-ledger.json`, fill its vars + `record_store`,
then validate → compose → compile → oversight → executor.

> Localized from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills) `pacsomatic` — MIT (see LICENSE.txt).
